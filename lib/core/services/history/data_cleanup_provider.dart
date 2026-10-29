import 'dart:async';
import 'dart:io';

import 'package:clipshare/core/database/app_database.dart';
import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/database/extensions/history_extension.dart';
import 'package:clipshare/core/scheduler/models/scheduled_task.dart';
import 'package:clipshare/core/scheduler/schedule/cron_schedule.dart';
import 'package:clipshare/core/scheduler/schedule/simple_task_handler.dart';
import 'package:clipshare/core/scheduler/scheduler.dart';
import 'package:clipshare/core/scheduler/scheduler_provider.dart';
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

  /// 固定任务标识，本服务按此 key 向全局调度器注册自动清理任务。
  static const schedulerKey = 'data_cleanup';

  /// 已注册的自动清理任务句柄，null 表示当前没有挂载调度任务。
  TaskHandle? _taskHandle;

  AppDatabase get _db => ref.read(appDbProvider).requireValue;

  DeviceNotifier get _deviceNotifier => ref.read(deviceProvider.notifier);

  SessionNotifier get _sessionNotifier => ref.read(sessionProvider.notifier);

  HistoryRecorderNotifier get _recorder => ref.read(historyRecorderProvider.notifier);

  ClipboardSourceNotifier get _clipboardSource => ref.read(clipboardSourceProvider.notifier);

  Device get _self => ref.read(localDeviceInfoProvider).requireValue.self;

  DataCleanupConfig? get _config => ref.read(dataCleanupConfigProvider).requireValue;

  Future<Scheduler> get _scheduler => ref.read(schedulerProvider.future);

  @override
  Future<void> build() async {
    // 任务由调度器统一释放，句柄仅作本地记录
    ref.onDispose(() {
      _taskHandle = null;
    });
    // 调度器与配置均可从库中恢复，启动时直接按配置对齐调度状态
    await configureAutoClean();
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

  /// 按已保存的自动清理配置对齐全局调度器中的任务：开启时注册，关闭或配置无效时注销
  Future<void> configureAutoClean() async {
    final cfg = await ref.read(dataCleanupConfigProvider.future);
    final cron = cfg?.cron;
    if (cfg == null || !cfg.autoClean || cron == null) {
      await _cancelAutoCleanTask();
      logger.debug(tag, 'auto clean disabled, task unregistered');
      return;
    }
    final schedule = CronSchedule(cron);
    if (schedule.nextRun(DateTime.now()) == null) {
      // cron 非法时不能保留旧任务，否则旧表达式会继续触发清理
      await _cancelAutoCleanTask();
      logger.error(tag, "invalid cron '$cron', skip scheduling");
      return;
    }
    final scheduler = await _scheduler;
    final task = ScheduledTask(
      key: schedulerKey,
      schedule: schedule,
      handler: SimpleTaskHandler((_) => cleanBySavedConfig()),
      // 启动或重设调度时补跑一次，等价于原实现「错过执行时间立即执行」
      runOnMissed: true,
      runImmediately: false,
    );
    // 同 key 重复注册由调度器覆盖旧任务，不会残留两个定时器
    final handle = await scheduler.register(task);
    _taskHandle = handle;
    logger.debug(tag, 'auto clean task registered, cron=$cron');
  }

  /// 注销已挂载的自动清理任务；未注册时无副作用。
  Future<void> _cancelAutoCleanTask() async {
    final handle = _taskHandle;
    _taskHandle = null;
    await handle?.cancel();
  }

  /// 按当前保存的清理配置执行一次自动清理并回写执行时间。
  ///
  /// 配置中不含来源 App 与日期范围，自动清理仅按标签/设备/类型/天数过滤。
  /// 回收孤儿设备失败不影响已完成的删除，只在日志中记录；清理本身抛异常时
  /// 不写回执行时间，交由调度器记录失败，避免界面显示为执行成功。
  Future<void> cleanBySavedConfig() async {
    final cfg = _config;
    if (cfg == null) {
      logger.warn(tag, 'clean data config not found, skip auto clean');
      return;
    }
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
    final cnt = await deleteCascade(params);
    // 历史已删除即视为本次清理生效，孤儿设备回收属于可失败的收尾步骤
    try {
      await _recycleOrphanDevices(params.devIds);
    } catch (err, stack) {
      logger.warn(tag, 'recycle orphan devices failed after auto clean. $err $stack');
    }
    logger.debug(tag, 'auto clean data success, deleted $cnt histories');
    await _updateCleanTime(cfg);
  }

  /// 回写最近一次清理与下次清理时间。
  ///
  /// 以库中最新配置为基准，只改写这两个字段，避免清理期间用户保存的其它配置被本次结果覆盖。
  Future<void> _updateCleanTime(DataCleanupConfig fallback) async {
    // 重新读库而非使用执行开始时的快照，清理耗时期间用户可能已保存新配置
    final current = await ref.read(dataCleanupConfigProvider.future);
    final base = current ?? fallback;
    final config = base.copyWith(
      lastCleanTime: DateTime.now(),
      nextCleanTime: CronUtil.getNextTime(base.cron ?? ''),
    );
    await _saveConfig(config);
  }

  /// 持久化清理配置并等待只读配置 provider 重建完成，避免后续读取拿到旧配置。
  Future<void> _saveConfig(DataCleanupConfig config) async {
    await _db.configDao.addOrUpdate(ConfigKey.cleanDataConfig, config.toString());
    final _ = await ref.refresh(dataCleanupConfigProvider.future);
  }
}
