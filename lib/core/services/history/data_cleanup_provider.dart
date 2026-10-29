import 'dart:async';
import 'dart:io';

import 'package:clipshare/core/database/app_database.dart';
import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/database/extensions/history_extension.dart';
import 'package:clipshare/core/services/clipboard/clipboard_source_provider.dart';
import 'package:clipshare/core/services/device/device_provider.dart';
import 'package:clipshare/core/services/device/local_device_info_provider.dart';
import 'package:clipshare/core/services/history/history_event.dart';
import 'package:clipshare/core/services/history/history_recorder_provider.dart';
import 'package:clipshare/core/services/transport/socket/session/session_provider.dart';
import 'package:clipshare/core/settings/data_cleanup/data_cleanup_config.dart';
import 'package:clipshare/core/settings/data_cleanup/data_cleanup_config_provider.dart';
import 'package:clipshare/shared/enums/config_key.dart';
import 'package:clipshare/shared/extensions/list_extension.dart';
import 'package:clipshare/shared/extensions/time_extension.dart';
import 'package:clipshare/shared/models/op_method.dart';
import 'package:clipshare/shared/utils/cron_util.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'data_cleanup_provider.g.dart';

/// 一次数据清理的过滤条件，由页面当前筛选或已保存配置解析得出。
class DataCleanupParams {
  /// 内容类型值列表（HistoryContentType.value）
  final List<String> types;

  /// 标签列表
  final List<String> tags;

  /// 设备 id 列表
  final List<String> devIds;

  /// 剪贴板来源 App id 列表
  final List<String> appIds;

  /// 起始日期（yyyy-MM-dd），空表示不限
  final String? startTime;

  /// 结束日期（yyyy-MM-dd），空表示不限
  final String? endTime;

  /// 是否同时删除本地文件
  final bool removeFiles;

  /// 是否保留置顶数据
  final bool saveTop;

  const DataCleanupParams({
    required this.types,
    required this.tags,
    required this.devIds,
    required this.appIds,
    this.startTime,
    this.endTime,
    this.removeFiles = false,
    this.saveTop = false,
  });
}

/// 数据清理服务
@Riverpod(keepAlive: true)
class DataCleanupNotifier extends _$DataCleanupNotifier {
  static const tag = 'DataCleanupNotifier';

  /// 级联删除的单批最大数量，防止 SQL in 子句元素过多。
  static const deleteBatchSize = 1000;

  Timer? _cleanTimer;

  AppDatabase get _db => ref.read(appDbProvider).requireValue;

  DeviceNotifier get _deviceNotifier => ref.read(deviceProvider.notifier);

  SessionNotifier get _sessionNotifier => ref.read(sessionProvider.notifier);

  HistoryRecorderNotifier get _recorder => ref.read(historyRecorderProvider.notifier);

  ClipboardSourceNotifier get _clipboardSource => ref.read(clipboardSourceProvider.notifier);

  Device get _self => ref.read(localDeviceInfoProvider).requireValue.self;

  DataCleanupConfig? get _config => ref.read(dataCleanupConfigProvider).requireValue;

  @override
  Future<void> build() async {
    ref.onDispose(() {
      _cleanTimer?.cancel();
    });
    // 启动即恢复自动清理定时器（错过的执行时间会立即补跑）
    await initAutoClean();
  }

  /// 解析清理的时间范围。
  /// 启用天数过滤时忽略起止日期，改为 [1970-01-01, 今天-保留天数]。
  static ({String? start, String? end}) resolveCleanTimeRange({
    required bool useDaysFilter,
    required int saveDays,
    String? startDate,
    String? endDate,
    DateTime? now,
  }) {
    if (!useDaysFilter) {
      return (start: startDate, end: endDate);
    }
    final today = now ?? DateTime.now();
    final endTime = today.add(Duration(days: -1 * saveDays)).format('yyyy-MM-dd');
    return (start: '1970-01-01', end: endTime);
  }

  /// 清理数据并回收孤儿设备，返回删除的历史条数。
  Future<int> cleanData(DataCleanupParams params) async {
    final cnt = await deleteCascade(params);
    await _recycleOrphanDevices(params.devIds);
    return cnt;
  }

  /// 清理指定设备的同步记录，返回删除条数（null 表示删除失败）。
  Future<int?> cleanDeviceSyncRecords(List<String> devIds) {
    return _db.operationSyncDao.deleteByDevIds(devIds);
  }

  /// 清理指定设备的操作记录，返回删除条数（null 表示删除失败）。
  Future<int?> cleanDeviceOperationRecords(List<String> devIds) {
    return _db.operationRecordDao.removeByDevIds(devIds);
  }

  /// 级联删除过滤命中的历史及其关联数据（操作记录、同步记录、标签、来源信息），可选删除本地文件。
  /// 返回删除的历史条数。
  Future<int> deleteCascade(DataCleanupParams params) async {
    final historyDao = _db.historyDao;
    final histories = await historyDao.getHistoriesWithFileContent(
      params.types,
      params.tags,
      params.devIds,
      params.appIds,
      params.startTime ?? '',
      params.endTime ?? '',
      params.saveTop,
    );
    // 防止 in 中 id 过多，分批处理
    final parts = histories.partition(deleteBatchSize);
    for (var part in parts) {
      final ids = part.map((item) => item.id).toList();
      // 先删除操作记录
      await _db.operationRecordDao.deleteByDataIds(ids.map((item) => item.toString()).toList());
      // 删除同步记录
      await _db.operationSyncDao.deleteByIds(ids);
      // 删除标签
      await _db.historyTagDao.deleteByHisIds(ids);
      // 删除历史
      await historyDao.deleteByIds(ids);
      // 通知历史列表移除已删记录
      for (var item in part) {
        _recorder.emitDelta(HistoryDeltaEvent(history: item, operation: OpMethod.delete));
      }
      // 移除未使用的剪贴板来源信息
      await _clipboardSource.removeNotUsed();
      // 删除文件
      if (params.removeFiles) {
        final files = part.where((item) => item.isFile || item.isImage).map((item) => item.content).toList();
        for (var filePath in files) {
          try {
            await File(filePath).delete();
          } catch (_) {}
        }
      }
    }
    return histories.length;
  }

  /// 清理后回收孤儿设备：设备历史已清空且离线未配对时删除设备记录。
  /// 任一设备不满足回收条件即停止处理后续设备（保持原实现行为）。
  Future<void> _recycleOrphanDevices(List<String> devIds) async {
    final selfId = _self.guid;
    for (var devId in devIds) {
      // 本机跳过
      if (devId == selfId) {
        return;
      }
      final cnt = await _db.historyDao.countByDevId(devId);
      if (cnt > 0) {
        // 数据未清空，跳过
        return;
      }
      // 如果设备离线并未配对则删除，否则不能删
      if (_sessionNotifier.isOnline(devId, true)) {
        return;
      }
      await _deviceNotifier.remove(devId);
    }
  }

  /// 初始化/重设自动清理定时器，保存自动清理配置后需重新调用。
  /// 错过的执行时间会立即静默补跑并滚动更新上/下次执行时间。
  Future<void> initAutoClean() async {
    _cleanTimer?.cancel();
    final cfg = _config;
    if (cfg == null || !cfg.autoClean) {
      logger.debug(tag, 'clean data config not found or disable auto clean');
      return;
    }
    final cron = cfg.cron;
    final nextTime = cfg.nextCleanTime;
    if (cron == null || nextTime == null) {
      // 配置不完整（如手动改库），无法调度
      logger.error(tag, 'auto clean config missing cron/nextCleanTime');
      return;
    }
    final now = DateTime.now();
    // 已经错过上次执行时间则立即执行
    if (now.isAfter(nextTime)) {
      try {
        await _cleanByConfig(cfg);
        logger.debug(tag, 'auto clean data success.');
        final newNextTime = CronUtil.getNextTime(cron);
        await _saveConfig(
          cfg.copyWith(
            lastCleanTime: now,
            nextCleanTime: newNextTime,
          ),
        );
      } catch (err, stack) {
        logger.debug(tag, 'auto clean data failed. $err $stack');
      }
    }
    // 设置定时器
    final newNextTime = CronUtil.getNextTime(cron);
    if (newNextTime == null) {
      logger.error(tag, "invalid cron '$cron', skip scheduling");
      return;
    }
    logger.debug(tag, 'set clean data timer, next execute time: $newNextTime');
    final diff = now.difference(newNextTime);
    _cleanTimer = Timer(Duration(seconds: diff.inSeconds.abs() + 1), () => initAutoClean());
  }

  /// 按已保存配置构建清理参数并静默执行。
  /// 配置中不含来源 App 与日期范围，自动清理仅按标签/设备/类型/天数过滤。
  Future<void> _cleanByConfig(DataCleanupConfig cfg) async {
    final timeRange = resolveCleanTimeRange(
      useDaysFilter: cfg.saveDays != null,
      saveDays: cfg.saveDays ?? 0,
    );
    final params = DataCleanupParams(
      types: cfg.contentTypes.map((item) => item.value).toList(),
      tags: cfg.tags.toList(),
      devIds: cfg.devIds.toList(),
      appIds: const [],
      startTime: timeRange.start,
      endTime: timeRange.end,
      removeFiles: cfg.removeFiles,
      saveTop: cfg.saveTopData,
    );
    await cleanData(params);
  }

  /// 持久化清理配置并刷新只读配置 provider。
  Future<void> _saveConfig(DataCleanupConfig config) async {
    await _db.configDao.addOrUpdate(ConfigKey.cleanDataConfig, config.toString());
    ref.invalidate(dataCleanupConfigProvider);
  }
}
