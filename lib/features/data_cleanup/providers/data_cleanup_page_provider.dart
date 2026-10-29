import 'dart:async';

import 'package:clipshare/core/database/app_database.dart';
import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/services/device/device_provider.dart';
import 'package:clipshare/core/services/device/local_device_info_provider.dart';
import 'package:clipshare/core/services/history/data_cleanup_provider.dart';
import 'package:clipshare/core/settings/data_cleanup/data_cleanup_config.dart';
import 'package:clipshare/core/settings/data_cleanup/data_cleanup_config_provider.dart';
import 'package:clipshare/core/settings/data_cleanup/data_cleanup_freq.dart';
import 'package:clipshare/features/data_cleanup/enums/week_day.dart';
import 'package:clipshare/features/data_cleanup/utils/data_cleanup_schedule.dart';
import 'package:clipshare/features/history/providers/history_provider.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/enums/history_content_type.dart';
import 'package:clipshare/shared/utils/dialog.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:clipshare/shared/utils/snackbar.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'data_cleanup_page_provider.g.dart';

/// 数据清理页面状态
class DataCleanupPageState {
  /// 全部标签
  final Set<String> allTags;

  /// 全部设备（含本机）
  final Set<Device> allDevices;

  /// 已选设备 id
  final Set<String> selectedDevs;

  /// 已选标签
  final Set<String> selectedTags;

  /// 已选来源 App id
  final Set<String> selectedSources;

  /// 已选内容类型
  final Set<HistoryContentType> selectedContentTypes;

  /// 自动清理频率
  final DataCleanupFreq frequency;

  /// 是否开启自动清理
  final bool autoClean;

  /// 是否保留置顶数据
  final bool saveTopData;

  /// 是否同时删除本地文件
  final bool removeFiles;

  /// 起始日期（yyyy-MM-dd）
  final String? startDate;

  /// 结束日期（yyyy-MM-dd）
  final String? endDate;

  /// 是否启用保留天数过滤
  final bool useDaysFilter;

  /// 保留天数
  final int saveDays;

  /// 周清理选中的星期
  final WeekDay? selectedWeekDay;

  /// 执行时（两位字符串）
  final String selectedHour;

  /// 执行分（两位字符串）
  final String selectedMinute;

  /// cron 模式下的表达式输入
  final String cronInput;

  /// 下次执行时间预览
  final DateTime? nextExecTime;

  const DataCleanupPageState({
    this.allTags = const {},
    this.allDevices = const {},
    this.selectedDevs = const {},
    this.selectedTags = const {},
    this.selectedSources = const {},
    this.selectedContentTypes = const {},
    this.frequency = DataCleanupFreq.day,
    this.autoClean = false,
    this.saveTopData = true,
    this.removeFiles = false,
    this.startDate,
    this.endDate,
    this.useDaysFilter = false,
    this.saveDays = 0,
    this.selectedWeekDay,
    this.selectedHour = '00',
    this.selectedMinute = '00',
    this.cronInput = '',
    this.nextExecTime,
  });

  DataCleanupPageState copyWith({
    Set<String>? allTags,
    Set<Device>? allDevices,
    Set<String>? selectedDevs,
    Set<String>? selectedTags,
    Set<String>? selectedSources,
    Set<HistoryContentType>? selectedContentTypes,
    DataCleanupFreq? frequency,
    bool? autoClean,
    bool? saveTopData,
    bool? removeFiles,
    String? startDate,
    String? endDate,
    bool? useDaysFilter,
    int? saveDays,
    WeekDay? selectedWeekDay,
    String? selectedHour,
    String? selectedMinute,
    String? cronInput,
    DateTime? nextExecTime,
  }) {
    return DataCleanupPageState(
      allTags: allTags ?? this.allTags,
      allDevices: allDevices ?? this.allDevices,
      selectedDevs: selectedDevs ?? this.selectedDevs,
      selectedTags: selectedTags ?? this.selectedTags,
      selectedSources: selectedSources ?? this.selectedSources,
      selectedContentTypes: selectedContentTypes ?? this.selectedContentTypes,
      frequency: frequency ?? this.frequency,
      autoClean: autoClean ?? this.autoClean,
      saveTopData: saveTopData ?? this.saveTopData,
      removeFiles: removeFiles ?? this.removeFiles,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      useDaysFilter: useDaysFilter ?? this.useDaysFilter,
      saveDays: saveDays ?? this.saveDays,
      selectedWeekDay: selectedWeekDay ?? this.selectedWeekDay,
      selectedHour: selectedHour ?? this.selectedHour,
      selectedMinute: selectedMinute ?? this.selectedMinute,
      cronInput: cronInput ?? this.cronInput,
      nextExecTime: nextExecTime ?? this.nextExecTime,
    );
  }
}

/// 数据清理页面状态与动作：负责过滤器编辑、配置保存与清理执行（含 UI 反馈）。
@riverpod
class DataCleanupPageNotifier extends _$DataCleanupPageNotifier {
  static const tag = 'DataCleanupPageNotifier';

  AppDatabase get _db => ref.read(appDbProvider).requireValue;
  Device get _self => ref.read(localDeviceInfoProvider).requireValue.self;
  DataCleanupConfig? get _config => ref.read(dataCleanupConfigProvider).requireValue;
  DataCleanupNotifier get _dataCleanup => ref.read(dataCleanupProvider.notifier);
  HistoriesNotifier get _histories => ref.read(historiesProvider.notifier);

  @override
  DataCleanupPageState build() {
    ref.listen(
      deviceProvider.select((state) => state.value?.storedList.map((dev) => dev.guid).join()),
      (_, __) => _reloadDevices(),
    );
    // 从已保存配置恢复过滤器
    var result = const DataCleanupPageState();
    final cfg = _config;
    if (cfg != null) {
      result = result.copyWith(
        selectedDevs: {...cfg.devIds},
        selectedTags: {...cfg.tags},
        selectedContentTypes: {...cfg.contentTypes},
        removeFiles: cfg.removeFiles,
        autoClean: cfg.autoClean,
        frequency: cfg.autoCleanFreq,
        cronInput: cfg.cron ?? '',
        useDaysFilter: cfg.saveDays != null,
        saveDays: cfg.saveDays ?? 0,
      );
    }
    // 异步加载标签与设备列表
    unawaited(_loadData());
    return _withNextExecTime(result);
  }

  /// 加载所有标签名与设备列表（含本机）
  Future<void> _loadData() async {
    final tags = await _db.historyTagDao.getAllTagNames();
    final deviceState = ref.read(deviceProvider).requireValue;
    final devices = <Device>{...deviceState.storedList, _self};
    state = state.copyWith(allTags: {...tags}, allDevices: devices);
  }

  /// 设备状态变化后重导设备列表，并从已选设备中剔除已删除的设备
  void _reloadDevices() {
    final deviceState = ref.read(deviceProvider).requireValue;
    final devices = <Device>{...deviceState.storedList, _self};
    final availableIds = devices.map((dev) => dev.guid).toSet();
    final selectedDevs = state.selectedDevs.where((id) => availableIds.contains(id)).toSet();
    state = state.copyWith(allDevices: devices, selectedDevs: selectedDevs);
  }

  /// 切换标签选中状态
  void toggleTag(String tag) {
    final tags = {...state.selectedTags};
    if (tags.contains(tag)) {
      tags.remove(tag);
    } else {
      tags.add(tag);
    }
    state = state.copyWith(selectedTags: tags);
  }

  /// 切换设备选中状态
  void toggleDev(String devId) {
    final devs = {...state.selectedDevs};
    if (devs.contains(devId)) {
      devs.remove(devId);
    } else {
      devs.add(devId);
    }
    state = state.copyWith(selectedDevs: devs);
  }

  /// 切换来源 App 选中状态
  void toggleSource(String appId) {
    final sources = {...state.selectedSources};
    if (sources.contains(appId)) {
      sources.remove(appId);
    } else {
      sources.add(appId);
    }
    state = state.copyWith(selectedSources: sources);
  }

  /// 追加选中的来源 App
  void addSources(Iterable<String> appIds) {
    final sources = {...state.selectedSources}..addAll(appIds);
    state = state.copyWith(selectedSources: sources);
  }

  /// 切换内容类型选中状态
  void toggleContentType(HistoryContentType type) {
    final types = {...state.selectedContentTypes};
    if (types.contains(type)) {
      types.remove(type);
    } else {
      types.add(type);
    }
    state = state.copyWith(selectedContentTypes: types);
  }

  /// 设置是否启用保留天数过滤
  void setUseDaysFilter(bool value) {
    state = state.copyWith(useDaysFilter: value);
  }

  /// 设置起始日期，null 表示清除
  void setStartDate(String? date) {
    state = state.copyWith(startDate: date);
  }

  /// 设置结束日期，null 表示清除
  void setEndDate(String? date) {
    state = state.copyWith(endDate: date);
  }

  /// 更新保留天数
  void updateSaveDays(int days) {
    state = state.copyWith(saveDays: days);
  }

  /// 设置是否保留置顶数据
  void setSaveTopData(bool value) {
    state = state.copyWith(saveTopData: value);
  }

  /// 设置是否同时删除本地文件
  void setRemoveFiles(bool value) {
    state = state.copyWith(removeFiles: value);
  }

  /// 设置是否开启自动清理
  void setAutoClean(bool value) {
    state = state.copyWith(autoClean: value);
  }

  /// 设置自动清理频率并重算下次执行时间
  void setFrequency(DataCleanupFreq freq) {
    state = _withNextExecTime(state.copyWith(frequency: freq));
  }

  /// 设置周清理星期并重算下次执行时间
  void setWeekDay(WeekDay day) {
    state = _withNextExecTime(state.copyWith(selectedWeekDay: day));
  }

  /// 设置执行时间（时分）并重算下次执行时间
  void setTime({required String hour, required String minute}) {
    state = _withNextExecTime(state.copyWith(selectedHour: hour, selectedMinute: minute));
  }

  /// 更新 cron 表达式输入并重算下次执行时间
  void updateCronInput(String text) {
    state = _withNextExecTime(state.copyWith(cronInput: text));
  }

  /// 按当前过滤器统计命中条数
  Future<int> countByFilter() async {
    final timeRange = _resolveTimeRange();
    final cnt = await _db.historyDao.count(
      state.selectedContentTypes.map((item) => item.value).toList(),
      state.selectedTags.toList(),
      state.selectedDevs.toList(),
      state.selectedSources.toList(),
      timeRange.start ?? '',
      timeRange.end ?? '',
      state.saveTopData,
    );
    return cnt ?? 0;
  }

  /// 执行数据清理（带加载弹窗与结果提示）
  Future<void> cleanData(BuildContext context) async {
    final dialog = dialogManager.loading(context);
    try {
      final cnt = await _dataCleanup.cleanData(_buildParams());
      unawaited(dialog.close());
      if (!context.mounted) {
        return;
      }
      snackbar.success(context, '${TranslationKey.deleteSuccess.tr}: $cnt ${TranslationKey.deleteItemsUnit.tr}');
    } catch (err, stack) {
      logger.error(tag, err, stack);
      unawaited(dialog.close());
      if (!context.mounted) {
        return;
      }
      snackbar.warn(context, TranslationKey.deletionFailed.tr);
    }
  }

  /// 清理选中设备的同步记录（带空选校验、加载弹窗与结果提示）
  Future<void> cleanDeviceSyncRecords(BuildContext context) async {
    final devIds = state.selectedDevs.toList();
    if (devIds.isEmpty) {
      dialogManager.tips(context, text: TranslationKey.pleaseSelectDevices.tr);
      return;
    }
    final dialog = dialogManager.loading(context);
    try {
      final cnt = await _dataCleanup.cleanDeviceSyncRecords(devIds);
      unawaited(dialog.close());
      if (!context.mounted) {
        return;
      }
      if (cnt == null) {
        snackbar.warn(context, TranslationKey.deletionFailed.tr);
      } else {
        snackbar.success(context, '${TranslationKey.deleteSuccess.tr}: $cnt ${TranslationKey.deleteItemsUnit.tr}');
        await _histories.refresh();
      }
    } catch (err, stack) {
      logger.error(tag, err, stack);
      unawaited(dialog.close());
      if (!context.mounted) {
        return;
      }
      snackbar.warn(context, TranslationKey.deletionFailed.tr);
    }
  }

  /// 清理选中设备的操作记录（带空选校验、加载弹窗与结果提示）
  Future<void> cleanDeviceOperationRecords(BuildContext context) async {
    final devIds = state.selectedDevs.toList();
    if (devIds.isEmpty) {
      dialogManager.tips(context, text: TranslationKey.pleaseSelectDevices.tr);
      return;
    }
    final dialog = dialogManager.loading(context);
    try {
      final cnt = await _dataCleanup.cleanDeviceOperationRecords(devIds);
      unawaited(dialog.close());
      if (!context.mounted) {
        return;
      }
      if (cnt == null) {
        snackbar.warn(context, TranslationKey.deletionFailed.tr);
      } else {
        snackbar.success(context, '${TranslationKey.deleteSuccess.tr}: $cnt 条');
        await _histories.refresh();
      }
    } catch (err, stack) {
      logger.error(tag, err, stack);
      unawaited(dialog.close());
      if (!context.mounted) {
        return;
      }
      snackbar.warn(context, TranslationKey.deletionFailed.tr);
    }
  }

  /// 保存过滤器配置
  Future<void> saveFilterConfig(BuildContext context) async {
    final cfg = _config;
    final newCfg = cfg == null ? _buildConfigFromFilter() : cfg.copyWith(
      tags: state.selectedTags.toList(),
      devIds: state.selectedDevs.toList(),
      contentTypes: state.selectedContentTypes.toList(),
      saveTopData: state.saveTopData,
      removeFile: state.removeFiles,
      saveDays: state.useDaysFilter ? state.saveDays : null,
    );
    try {
      await _saveConfig(newCfg);
      if (!context.mounted) {
        return;
      }
      dialogManager.tips(context, text: TranslationKey.saveSuccess.tr);
    } catch (err, stack) {
      if (!context.mounted) {
        return;
      }
      dialogManager.tips(context, text: '${TranslationKey.saveFailed.tr}\n$err\n$stack');
    }
  }

  /// 保存自动清理配置并重设定时器
  Future<void> saveAutoCleanConfig(BuildContext context) async {
    final nextTime = state.nextExecTime;
    if (nextTime == null) {
      dialogManager.tips(context, text: TranslationKey.errorCronTips.tr);
      return;
    }
    final cfg = _config;
    if (cfg == null) {
      dialogManager.tips(context, text: TranslationKey.pleaseSaveFilterConfig.tr);
      return;
    }
    final cron = _buildCron();
    final newCfg = cfg.copyWith(
      autoClean: state.autoClean,
      cron: cron,
      autoCleanFreq: state.frequency,
      nextCleanTime: nextTime,
    );
    try {
      await _saveConfig(newCfg);
      if (!context.mounted) {
        return;
      }
      dialogManager.tips(context, text: TranslationKey.saveSuccess.tr);
      await _dataCleanup.initAutoClean();
    } catch (err, stack) {
      if (!context.mounted) {
        return;
      }
      dialogManager.tips(context, text: '${TranslationKey.saveFailed.tr}\n$err\n$stack');
    }
  }

  /// 以当前过滤器构建全新清理配置
  DataCleanupConfig _buildConfigFromFilter() {
    return DataCleanupConfig(
      tags: state.selectedTags.toList(),
      devIds: state.selectedDevs.toList(),
      contentTypes: state.selectedContentTypes.toList(),
      saveTopData: state.saveTopData,
      removeFiles: state.removeFiles,
      saveDays: state.useDaysFilter ? state.saveDays : null,
    );
  }

  /// 以当前过滤器构建清理参数
  DataCleanupParams _buildParams() {
    final timeRange = _resolveTimeRange();
    return DataCleanupParams(
      types: state.selectedContentTypes.map((item) => item.value).toList(),
      tags: state.selectedTags.toList(),
      devIds: state.selectedDevs.toList(),
      appIds: state.selectedSources.toList(),
      startTime: timeRange.start,
      endTime: timeRange.end,
      removeFiles: state.removeFiles,
      saveTop: state.saveTopData,
    );
  }

  /// 解析当前过滤的时间范围（天数过滤启用时忽略起止日期）
  ({String? start, String? end}) _resolveTimeRange() {
    return DataCleanupNotifier.resolveCleanTimeRange(
      useDaysFilter: state.useDaysFilter,
      saveDays: state.saveDays,
      startDate: state.startDate,
      endDate: state.endDate,
    );
  }

  /// 按当前频率/时间/cron 输入构建 cron 表达式
  String _buildCron() {
    return buildCronExpression(
      frequency: state.frequency,
      minute: state.selectedMinute,
      hour: state.selectedHour,
      weekDay: state.selectedWeekDay,
      cronInput: state.cronInput,
    );
  }

  /// 依据当前频率/时间/cron 输入计算下次执行时间
  DataCleanupPageState _withNextExecTime(DataCleanupPageState value) {
    final cron = buildCronExpression(
      frequency: value.frequency,
      minute: value.selectedMinute,
      hour: value.selectedHour,
      weekDay: value.selectedWeekDay,
      cronInput: value.cronInput,
    );
    return value.copyWith(nextExecTime: nextExecTimeOf(cron));
  }

  /// 持久化清理配置并刷新只读配置 provider
  Future<void> _saveConfig(DataCleanupConfig config) async {
    await _db.configDao.addOrUpdate(.cleanDataConfig, config.toString());
    ref.invalidate(dataCleanupConfigProvider);
  }
}
