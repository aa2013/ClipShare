import 'dart:async';
import 'dart:io';

import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:clipshare/app/data/enums/clean_data_freq.dart';
import 'package:clipshare/app/data/enums/history_content_type.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/enums/week_day.dart';
import 'package:clipshare/app/data/models/clean_data_config.dart';
import 'package:clipshare/app/data/models/clip_data.dart';
import 'package:clipshare/app/data/models/dev_info.dart';
import 'package:clipshare/app/data/models/version.dart';
import 'package:clipshare/app/data/repository/entity/tables/device.dart';
import 'package:clipshare/app/listeners/device_remove_listener.dart';
import 'package:clipshare/app/modules/history_module/history_controller.dart';
import 'package:clipshare/app/modules/search_module/search_controller.dart' as search_module;
import 'package:clipshare/app/services/clipboard_source_service.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/services/device_service.dart';
import 'package:clipshare/app/services/socket_service.dart';
import 'package:clipshare/app/utils/cron_util.dart';
import 'package:clipshare/app/utils/extensions/list_extension.dart';
import 'package:clipshare/app/utils/extensions/time_extension.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:clipshare/app/widgets/radio_group.dart';
import 'package:clipshare/app/widgets/single_select_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../widgets/empty_content.dart';
/**
 * GetX Template Generator - fb.com/htngu.99
 * */

class CleanDataController extends GetxController implements DeviceRemoveListener, DevAliveListener {
  final dbService = Get.find<DbService>();
  final appConfig = Get.find<ConfigService>();
  final devService = Get.find<DeviceService>();
  final sktService = Get.find<SocketService>();
  final sourceService = Get.find<ClipboardSourceService>();
  final logTag = "CleanDataController";
  final allDevices = <Device>{}.obs;
  final allTags = <String>{}.obs;

  //region 搜索条件
  final selectedDevs = <String>{}.obs;
  final selectedTags = <String>{}.obs;
  final selectedSources = <String>{}.obs;
  final selectedContentTypes = <HistoryContentType>{}.obs;

  //endregion

  final frequency = CleanDataFreq.day.obs;
  final autoClean = false.obs;
  final saveTopData = true.obs;
  final removeFiles = false.obs;
  final startDate = Rx<String?>(null);
  final endDate = Rx<String?>(null);
  final selectedWeekDay = Rx<WeekDay?>(null);
  final selectedHour = Rx<String>("00");
  final selectedMinute = Rx<String>("00");
  final nextExecTime = Rx<String?>(null);
  final cronInputCtl = TextEditingController();
  Timer? cleanDataTimer;
  final emptyFilter = EmptyContent(
    size: 40,
    showText: false,
  );

  Map<CleanDataFreq, Widget> get freqSegmented {
    final labels = {
      CleanDataFreq.day: TranslationKey.daily.tr,
      CleanDataFreq.week: TranslationKey.weekly.tr,
      CleanDataFreq.cron: "Cron",
    };
    final res = <CleanDataFreq, Widget>{};
    for (var key in labels.keys) {
      res[key] = Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        child: Text(labels[key]!),
      );
    }
    return res;
  }

  @override
  void onReady() {
    super.onReady();
    devService.addDevRemoveListener(this);
    sktService.addDevAliveListener(this);
    final cfg = appConfig.cleanDataConfig;
    if (cfg != null) {
      selectedDevs.addAll(cfg.devIds);
      selectedTags.addAll(cfg.tags);
      selectedContentTypes.addAll(cfg.contentTypes);
      removeFiles.value = cfg.removeFiles;
      autoClean.value = cfg.autoClean;
      frequency.value = cfg.autoCleanFreq;
      cronInputCtl.text = cfg.cron ?? "";
    }
    loadData();
  }

  @override
  void onClose() {
    devService.removeDevRemoveListener(this);
    sktService.removeDevAliveListener(this);
  }

  ///加载搜索条件
  Future<void> loadData() async {
    //加载所有标签名
    allTags.value = <String>{}..addAll(await dbService.historyTagDao.getAllTagNames());
    //加载所有设备名
    var tmpLst = await dbService.deviceDao.getAllDevices(appConfig.userId);
    print("load data");
    tmpLst.add(appConfig.device);
    allDevices.value = <Device>{}..addAll(tmpLst);
    updateNextExecTime();
  }

  ///选择日期范围
  Future<void> showDateRangeSelectDialog() async {
    //显示日期选择器
    var range = await showCalendarDatePicker2Dialog(
      context: Get.context!,
      config: CalendarDatePicker2WithActionButtonsConfig(
        calendarType: CalendarDatePicker2Type.range,
      ),
      dialogSize: const Size(325, 400),
      borderRadius: BorderRadius.circular(15),
    );
    if (range != null) {
      startDate.value = range[0]!.format("yyyy-MM-dd");
      endDate.value = range[1]!.format("yyyy-MM-dd");
    }
  }

  ///选择时间（时分）
  Future<void> showTimeSelectDialog() async {
    final TimeOfDay? picked = await showTimePicker(
      context: Get.context!,
      initialTime: TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked == null) return;
    selectedHour.value = picked.hour.toString().padLeft(2, "0");
    selectedMinute.value = picked.minute.toString().padLeft(2, "0");
    updateNextExecTime();
  }

  ///选择一周的某一天
  void showWeekDaySelectDialog() {
    SingleSelectDialog.show(
      selections: WeekDay.values.map((w) => RadioData(value: w.value, label: w.label)).toList(),
      title: Text(TranslationKey.selectWeekDay.tr),
      context: Get.context!,
      defaultValue: selectedWeekDay.value?.value ?? WeekDay.monday.value,
      onSelected: (selected) {
        Future.delayed(
          const Duration(milliseconds: 100),
        ).then(
          (_) {
            selectedWeekDay.value = WeekDay.parse(selected);
            updateNextExecTime();
            Get.back();
          },
        );
      },
    );
  }

  ///更新下次执行时间
  DateTime? updateNextExecTime() {
    final nextTime = CronUtil.getNextTime(_getCronExpress());
    nextExecTime.value = nextTime?.format();
    return nextTime;
  }

  ///获取Cron表达式
  String _getCronExpress() {
    String cronStr = cronInputCtl.text.trim();
    if (frequency.value == CleanDataFreq.day) {
      cronStr = "${selectedMinute.value} ${selectedHour.value} * * *";
    } else if (frequency.value == CleanDataFreq.week) {
      cronStr = "${selectedMinute.value} ${selectedHour.value} * * ${selectedWeekDay.value?.value ?? 1}";
    }
    return cronStr;
  }

  ///清理数据
  Future<void> cleanData([bool mute = false]) async {
    if (!mute) {
      Global.showLoadingDialog(context: Get.context!);
    }
    deleteCascade(
      uid: appConfig.userId,
      types: selectedContentTypes.map((item) => item.value).toList(),
      tags: selectedTags.toList(),
      devIds: selectedDevs.toList(),
      appIds: selectedSources.toList(),
      startTime: startDate.value,
      endTime: endDate.value,
      removeFiles: removeFiles.value,
      saveTop: saveTopData.value,
    ).then((cnt) async {
      if (!mute) {
        //关闭加载弹窗
        Get.back();
        Global.showSnackBarSuc(context: Get.context!, text: "${TranslationKey.deleteSuccess.tr}: $cnt ${TranslationKey.deleteItemsUnit.tr}");
      }
      refreshHistoryPage();
      final devs = selectedDevs.toList();
      for (var devId in devs) {
        //本机跳过
        if (devId == appConfig.device.guid) {
          return;
        }
        final cnt = await dbService.historyDao.countByDevId(devId, appConfig.userId);
        if (cnt > 0) {
          //数据未清空，跳过
          return;
        }
        //如果设备离线并未配对则删除，否则不能删
        if (sktService.isOnline(devId, true)) {
          print("is online");
          return;
        }
        var success = await devService.remove(devId);
        print("delete device success $success");
        if (success) {}
      }
    }).catchError((err, stack) {
      Log.error(logTag, "$err: $stack");
      if (!mute) {
        //关闭加载弹窗
        Get.back();
        Global.showSnackBarWarn(context: Get.context!, text: TranslationKey.deletionFailed.tr);
      }
    });
  }

  ///清理设备同步记录
  void cleanDeviceSyncRecords() {
    if (selectedDevs.isEmpty) {
      Global.showTipsDialog(context: Get.context!, text: TranslationKey.pleaseSelectDevices.tr);
      return;
    }
    Global.showLoadingDialog(context: Get.context!);
    dbService.opSyncDao.deleteByDevIds(appConfig.userId, selectedDevs.toList()).then((cnt) {
      //关闭加载弹窗
      Get.back();
      if (cnt == null) {
        Global.showSnackBarWarn(context: Get.context!, text: TranslationKey.deletionFailed.tr);
      } else {
        Global.showSnackBarSuc(context: Get.context!, text: "${TranslationKey.deleteSuccess.tr}: $cnt ${TranslationKey.deleteItemsUnit.tr}");
        refreshHistoryPage();
      }
    }).catchError((err, stack) {
      Log.error(logTag, "$err: $stack");
      //关闭加载弹窗
      Get.back();
      Global.showSnackBarWarn(context: Get.context!, text: TranslationKey.deletionFailed.tr);
    });
  }

  ///清理设备操作记录
  void cleanDeviceOperationRecords() {
    if (selectedDevs.isEmpty) {
      Global.showTipsDialog(context: Get.context!, text: TranslationKey.pleaseSelectDevices.tr);
      return;
    }
    Global.showLoadingDialog(context: Get.context!);
    dbService.opRecordDao.removeByDevIds(appConfig.userId, selectedDevs.toList()).then((cnt) {
      //关闭加载弹窗
      Get.back();
      if (cnt == null) {
        Global.showSnackBarWarn(context: Get.context!, text: TranslationKey.deletionFailed.tr);
      } else {
        Global.showSnackBarSuc(context: Get.context!, text: "${TranslationKey.deleteSuccess.tr}: $cnt 条");
        refreshHistoryPage();
      }
    }).catchError((err, stack) {
      Log.error(logTag, "$err: $stack");
      //关闭加载弹窗
      Get.back();
      Global.showSnackBarWarn(context: Get.context!, text: TranslationKey.deletionFailed.tr);
    });
  }

  ///保存过滤器配置
  void saveFilterConfig() {
    final cfg = appConfig.cleanDataConfig;
    if (cfg != null) {
      appConfig
          .setCleanDataConfig(
        cfg.copyWith(
          tags: selectedTags.toList(),
          devIds: selectedDevs.toList(),
          contentTypes: selectedContentTypes.toList(),
          saveTopData: saveTopData.value,
          removeFile: removeFiles.value,
        ),
      )
          .then((_) {
        Global.showTipsDialog(context: Get.context!, text: TranslationKey.saveSuccess.tr);
      }).catchError((err, stack) {
        Global.showTipsDialog(context: Get.context!, text: "${TranslationKey.saveSuccess.tr}\n$err\n$stack");
      });
    } else {
      appConfig
          .setCleanDataConfig(
        CleanDataConfig(
          tags: selectedTags.toList(),
          devIds: selectedDevs.toList(),
          contentTypes: selectedContentTypes.toList(),
          saveTopData: saveTopData.value,
          removeFiles: removeFiles.value,
        ),
      )
          .then((_) {
        Global.showTipsDialog(context: Get.context!, text: TranslationKey.saveSuccess.tr);
      }).catchError((err, stack) {
        Global.showTipsDialog(context: Get.context!, text: "${TranslationKey.saveSuccess.tr}\n$err\n$stack");
      });
    }
  }

  ///保存自动清理配置
  void saveAutoCleanConfig() {
    final nextTime = updateNextExecTime();
    if (nextTime == null) {
      Global.showTipsDialog(context: Get.context!, text: TranslationKey.errorCronTips.tr);
      return;
    }
    final cfg = appConfig.cleanDataConfig;
    if (cfg == null) {
      Global.showTipsDialog(context: Get.context!, text: TranslationKey.pleaseSaveFilterConfig.tr);
      return;
    }
    appConfig
        .setCleanDataConfig(
      cfg.copyWith(
        autoClean: autoClean.value,
        cron: _getCronExpress(),
        autoCleanFreq: frequency.value,
        nextCleanTime: DateTime.tryParse(nextExecTime.value!),
      ),
    )
        .then((_) {
      Global.showTipsDialog(context: Get.context!, text: TranslationKey.saveSuccess.tr);
      initAutoClean();
    }).catchError((err, stack) {
      Global.showTipsDialog(context: Get.context!, text: "${TranslationKey.saveFailed.tr}\n$err\n$stack");
    });
  }

  ///级联删除
  Future<int> deleteCascade({
    required int uid,
    List<String>? types,
    List<String>? tags,
    List<String>? devIds,
    List<String>? appIds,
    String? startTime,
    String? endTime,
    bool removeFiles = false,
    bool saveTop = false,
  }) async {
    final histories = await dbService.historyDao.getHistoriesWithFileContent(
      uid,
      types ?? [],
      tags ?? [],
      devIds ?? [],
      appIds ?? [],
      startTime ?? "",
      endTime ?? "",
      saveTop,
    );
    //防止在in中id过多，进行分部处理
    final parts = histories.partition(1000);
    for (var part in parts) {
      final ids = part.map((item) => item.id).toList().cast<int>();
      //先删除操作记录
      await dbService.opRecordDao.deleteByDataIds(ids.map((item) => item.toString()).toList());
      //删除同步记录
      await dbService.opSyncDao.deleteByIds(uid, ids);
      //删除标签
      await dbService.historyTagDao.deleteByHisIds(ids);
      //删除历史
      await dbService.historyDao.deleteByIds(ids, uid);
      //移除未使用的剪贴板来源信息
      await sourceService.removeNotUsed();
      //删除文件
      if (removeFiles) {
        //提取所有文件路径
        final files = part
            .where((item) {
              final data = ClipData(item);
              return data.isFile || data.isImage;
            })
            .map((item) => item.content)
            .toList();
        for (var filePath in files) {
          try {
            final file = File(filePath);
            file.deleteSync();
          } catch (_) {}
        }
      }
    }
    return histories.length;
  }

  ///刷新历史页面
  void refreshHistoryPage() {
    final historyController = Get.find<HistoryController>();
    final searchController = Get.find<search_module.SearchController>();
    historyController.refreshData();
    searchController.refreshData();
  }

  ///初始化自动清理定时器
  Future<void> initAutoClean() async {
    cleanDataTimer?.cancel();
    var cfg = appConfig.cleanDataConfig;
    if (cfg == null || !cfg.autoClean) {
      Log.debug(logTag, "clean data config not found or disable auto clean");
      return;
    }
    final nextTime = cfg.nextCleanTime!;
    final now = DateTime.now();
    //已经错过上次执行时间则立即执行
    if (now.isAfter(nextTime)) {
      await cleanData(true).then((_) {
        Log.debug(logTag, "auto clean data success.");
        final newNextTime = CronUtil.getNextTime(cfg.cron!);
        appConfig.setCleanDataConfig(
          cfg.copyWith(
            lastCleanTime: now,
            nextCleanTime: newNextTime,
          ),
        );
      }).catchError((err, stack) {
        Log.debug(logTag, "auto clean data failed. $err $stack");
      });
    }
    //设置定时器
    final newNextTime = CronUtil.getNextTime(cfg.cron!)!;
    Log.debug(logTag, "set clean data timer, next execute time: $newNextTime");
    final diff = now.difference(newNextTime);
    cleanDataTimer = Timer(Duration(seconds: diff.inSeconds.abs() + 1), initAutoClean);
  }

  //region ignore

  @override
  void onCancelPairing(DevInfo dev) {
    return;
  }

  @override
  void onConnected(DevInfo info, AppVersion minVersion, AppVersion version, bool isForward) {
    return;
  }

  @override
  void onDisconnected(String devId) {
    return;
  }

  @override
  void onForget(DevInfo dev, int uid) {
    return;
  }

  //endregion

  @override
  void onPaired(DevInfo dev, int uid, bool result, String? address) {}

  @override
  void onRemove(String devId) {
    print("on remove $devId");
    allDevices.removeWhere((item) => item.guid == devId);
    selectedDevs.remove(devId);
  }
}
