import 'package:clipshare/app/data/enums/clean_data_freq.dart';
import 'package:clipshare/app/data/enums/history_content_type.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/enums/week_day.dart';
import 'package:clipshare/app/data/models/local_app_info.dart';
import 'package:clipshare/app/modules/clean_data_module/clean_data_controller.dart';
import 'package:clipshare/app/modules/views/app_selection_page.dart';
import 'package:clipshare/app/services/clipboard_source_service.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/services/device_service.dart';
import 'package:clipshare/app/utils/extensions/time_extension.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/widgets/app_icon.dart';
import 'package:clipshare/app/widgets/app_info_groups_view.dart';
import 'package:clipshare/app/widgets/dynamic_size_widget.dart';
import 'package:clipshare/app/widgets/rounded_chip.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
/**
 * GetX Template Generator - fb.com/htngu.99
 * */

class CleanDataPage extends GetView<CleanDataController> {
  final sourceService = Get.find<ClipboardSourceService>();
  final devService = Get.find<DeviceService>();
  final appConfig = Get.find<ConfigService>();

  @override
  Widget build(BuildContext context) {
    final currentTheme = Theme.of(context);
    final appConfig = Get.find<ConfigService>();
    final dbService = Get.find<DbService>();
    final showAppBar = appConfig.isSmallScreen;
    final content = SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: Theme.of(context).cardTheme.color,
            elevation: 0,
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ///region 过滤器标题
                  Row(
                    children: [
                      const Icon(
                        Icons.filter_alt_rounded,
                        color: Colors.blueGrey,
                        size: 20,
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      Text(
                        TranslationKey.filter.tr,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          Global.showTipsDialog(context: Get.context!, text: TranslationKey.filterTips.tr);
                        },
                        icon: const Icon(
                          Icons.info_outline,
                          color: Colors.blueGrey,
                          size: 18,
                        ),
                      ),
                    ],
                  ),

                  ///endregion

                  ///region 标签过滤
                  Row(
                    children: [
                      const Icon(
                        Icons.tag,
                        color: Colors.blueGrey,
                        size: 16,
                      ),
                      const SizedBox(
                        width: 2,
                      ),
                      Text(
                        TranslationKey.filterByTag.tr,
                        style: const TextStyle(color: Colors.blueGrey),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  Obx(
                    () => Visibility(
                      replacement: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [controller.emptyFilter],
                      ),
                      visible: controller.allTags.isNotEmpty,
                      child: Obx(
                        () => Wrap(
                          direction: Axis.horizontal,
                          children: [
                            for (var tag in controller.allTags)
                              Container(
                                margin: const EdgeInsets.only(
                                  right: 5,
                                  bottom: 5,
                                ),
                                child: RoundedChip(
                                  onPressed: () {
                                    final selected = controller.selectedTags.contains(tag);
                                    if (selected) {
                                      controller.selectedTags.remove(tag);
                                    } else {
                                      controller.selectedTags.add(tag);
                                    }
                                  },
                                  selected: controller.selectedTags.contains(tag),
                                  label: Text(tag),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  ///endregion

                  ///region 设备过滤
                  Row(
                    children: [
                      const Icon(
                        Icons.devices_outlined,
                        color: Colors.blueGrey,
                        size: 16,
                      ),
                      const SizedBox(
                        width: 2,
                      ),
                      Text(
                        TranslationKey.filterByDevice.tr,
                        style: const TextStyle(color: Colors.blueGrey),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  Obx(
                    () => Wrap(
                      direction: Axis.horizontal,
                      children: controller.allDevices.map((dev) {
                        return Container(
                          margin: const EdgeInsets.only(right: 5, bottom: 5),
                          child: RoundedChip(
                            onPressed: () {
                              final selected = controller.selectedDevs.contains(dev.guid);
                              if (selected) {
                                controller.selectedDevs.remove(dev.guid);
                              } else {
                                controller.selectedDevs.add(dev.guid);
                              }
                            },
                            selected: controller.selectedDevs.contains(dev.guid),
                            label: Text(dev.name),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  ///endregion

                  ///region 来源过滤
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              MdiIcons.listBoxOutline,
                              color: Colors.blueGrey,
                              size: 16,
                            ),
                            const SizedBox(
                              width: 2,
                            ),
                            Text(
                              TranslationKey.filterBySource.tr,
                              style: const TextStyle(color: Colors.blueGrey),
                            ),
                          ],
                        ),
                      ),
                      RoundedChip(
                        avatar: const Icon(Icons.add),
                        label: Text(TranslationKey.selection.tr),
                        onPressed: () {
                          final page = AppSelectionPage(
                            loadDeviceName: devService.getName,
                            selectedIds: controller.selectedSources,
                            loadAppInfos: () {
                              final list = sourceService.appInfos.map((item) => LocalAppInfo.fromAppInfo(item, false)).toList();
                              return Future<List<LocalAppInfo>>.value(list);
                            },
                            onSelectedDone: (selected) {
                              controller.selectedSources.addAll(selected.map((item) => item.appId));
                            },
                          );
                          if (appConfig.isSmallScreen) {
                            Get.to(page);
                          } else {
                            Global.showDialog(context, DynamicSizeWidget(child: page));
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Obx(() {
                    final selectedAppIds = controller.selectedSources;
                    final selectedApps = sourceService.appInfos.where((app) => selectedAppIds.contains(app.appId)).toList();
                    return AppInfoGroupsView(
                      appInfos: selectedApps,
                      onPress: (app) {
                        final appId = app.appId;
                        final selected = controller.selectedSources.contains(appId);
                        if (selected) {
                          controller.selectedSources.remove(appId);
                        } else {
                          controller.selectedSources.add(appId);
                        }
                      },
                      loadDevName: devService.getName,
                    );
                  }),

                  ///endregion

                  ///region 日期过滤
                  Row(
                    children: [
                      const Icon(
                        Icons.date_range,
                        color: Colors.blueGrey,
                        size: 16,
                      ),
                      const SizedBox(
                        width: 2,
                      ),
                      Text(
                        TranslationKey.filterByDate.tr,
                        style: const TextStyle(color: Colors.blueGrey),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 4,
                  ),

                  Row(
                    children: [
                      Obx(
                        () => RoundedChip(
                          onPressed: controller.showDateRangeSelectDialog,
                          label: Obx(
                            () => Text(
                              controller.startDate.value ?? TranslationKey.startDate.tr,
                              style: const TextStyle(
                                color: Colors.blueGrey,
                              ),
                            ),
                          ),
                          avatar: const Icon(Icons.date_range_outlined),
                          deleteIcon: Obx(
                            () => Visibility(
                              visible: controller.startDate.value == null,
                              replacement: const Icon(
                                Icons.close,
                                size: 17,
                                color: Colors.blue,
                              ),
                              child: const Icon(
                                Icons.location_on,
                                size: 17,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                          deleteButtonTooltipMessage: controller.startDate.value == null ? TranslationKey.toToday.tr : TranslationKey.clear.tr,
                          onDeleted: () {
                            final startDate = controller.startDate.value;
                            if (startDate == null) {
                              controller.startDate.value = DateTime.now().format("yyyy-MM-dd");
                            } else {
                              controller.startDate.value = null;
                            }
                          },
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(right: 10, left: 10),
                        child: const Text("-"),
                      ),
                      Obx(
                        () => RoundedChip(
                          onPressed: controller.showDateRangeSelectDialog,
                          label: Obx(
                            () => Text(
                              controller.endDate.value ?? TranslationKey.endDate.tr,
                              style: const TextStyle(
                                color: Colors.blueGrey,
                              ),
                            ),
                          ),
                          avatar: const Icon(Icons.date_range_outlined),
                          deleteIcon: Obx(
                            () => Visibility(
                              visible: controller.endDate.value == null,
                              replacement: const Icon(
                                Icons.close,
                                size: 17,
                                color: Colors.blue,
                              ),
                              child: const Icon(
                                Icons.location_on,
                                size: 17,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                          deleteButtonTooltipMessage: controller.endDate.value == null ? TranslationKey.toToday.tr : TranslationKey.clear.tr,
                          onDeleted: () {
                            final endDate = controller.endDate.value;
                            if (endDate == null) {
                              controller.endDate.value = DateTime.now().format("yyyy-MM-dd");
                            } else {
                              controller.endDate.value = null;
                            }
                          },
                        ),
                      ),
                    ],
                  ),

                  ///endregion

                  ///region 内容类型过滤
                  Row(
                    children: [
                      const Icon(
                        Icons.category,
                        color: Colors.blueGrey,
                        size: 16,
                      ),
                      const SizedBox(
                        width: 2,
                      ),
                      Text(
                        TranslationKey.filterByContentType.tr,
                        style: const TextStyle(color: Colors.blueGrey),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  Obx(
                    () => SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (var type in [
                            HistoryContentType.text,
                            HistoryContentType.image,
                            HistoryContentType.file,
                            HistoryContentType.sms,
                          ])
                            Row(
                              children: [
                                RoundedChip(
                                  selected: controller.selectedContentTypes.contains(type),
                                  onPressed: () {
                                    final selected = controller.selectedContentTypes.contains(type);
                                    if (selected) {
                                      controller.selectedContentTypes.remove(type);
                                    } else {
                                      controller.selectedContentTypes.add(type);
                                    }
                                  },
                                  selectedColor: Theme.of(context).chipTheme.selectedColor,
                                  label: Text(type.label),
                                ),
                                const SizedBox(
                                  width: 5,
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),

                  ///endregion

                  ///region 可选项
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        TranslationKey.saveTopData.tr,
                        style: const TextStyle(fontSize: 16),
                      ),
                      Obx(
                        () => Switch(
                          value: controller.saveTopData.value,
                          onChanged: (checked) {
                            HapticFeedback.mediumImpact();
                            controller.saveTopData.value = checked;
                          },
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        TranslationKey.removeLocalFiles.tr,
                        style: const TextStyle(fontSize: 16),
                      ),
                      Obx(
                        () => Switch(
                          value: controller.removeFiles.value,
                          onChanged: (checked) {
                            HapticFeedback.mediumImpact();
                            controller.removeFiles.value = checked;
                          },
                        ),
                      ),
                    ],
                  ),

                  ///endregion

                  ///region 操作按钮
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            controller.saveFilterConfig();
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.save,
                                size: 16,
                              ),
                              const SizedBox(
                                width: 5,
                              ),
                              Text(TranslationKey.saveFilterConfig.tr),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextButton(
                          onPressed: () async {
                            final cnt =
                                await dbService.historyDao.count(
                                  appConfig.userId,
                                  controller.selectedContentTypes.map((item) => item.value).toList(),
                                  controller.selectedTags.toList(),
                                  controller.selectedDevs.toList(),
                                  controller.selectedSources.toList(),
                                  controller.startDate.value ?? "",
                                  controller.endDate.value ?? "",
                                  controller.saveTopData.value,
                                ) ??
                                0;
                            if (cnt == 0) {
                              Global.showSnackBarSuc(context: Get.context!, text: TranslationKey.noDataFromFilter.tr);
                              return;
                            }
                            Global.showTipsDialog(
                              context: context,
                              text: TranslationKey.filterCleaningConfirmation.trParams({'cnt': cnt.toString()}),
                              showCancel: true,
                              onOk: () {
                                controller.cleanData();
                              },
                            );
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.clear_all_outlined,
                              ),
                              const SizedBox(
                                width: 5,
                              ),
                              Text(TranslationKey.cleanData.tr),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      Global.showTipsDialog(
                        context: context,
                        text: TranslationKey.syncRecordsCleaningConfirmation.tr,
                        showCancel: true,
                        onOk: () {
                          controller.cleanDeviceSyncRecords();
                        },
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.notification_important_outlined,
                          size: 16,
                          color: Colors.deepOrange,
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        Text(
                          TranslationKey.syncRecordsCleanBtn.tr,
                          style: const TextStyle(color: Colors.deepOrange),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Global.showTipsDialog(
                        context: context,
                        text: TranslationKey.optionRecordsCleaningConfirmation.tr,
                        showCancel: true,
                        onOk: () {
                          controller.cleanDeviceOperationRecords();
                        },
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.notification_important_outlined,
                          size: 16,
                          color: Colors.deepOrange,
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        Text(
                          TranslationKey.optionRecordsCleanBtn.tr,
                          style: const TextStyle(color: Colors.deepOrange),
                        ),
                      ],
                    ),
                  ),

                  ///endregion
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Card(
            color: Theme.of(context).cardTheme.color,
            elevation: 0,
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  ///region 标题
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.timer,
                            color: Colors.blueGrey,
                            size: 20,
                          ),
                          const SizedBox(
                            width: 5,
                          ),
                          Text(
                            TranslationKey.autoCleanConfigTitle.tr,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Obx(
                            () => Switch(
                              value: controller.autoClean.value,
                              onChanged: (checked) {
                                HapticFeedback.mediumImpact();
                                controller.autoClean.value = checked;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  ///endregion

                  ///region 清理频率
                  Row(
                    children: [
                      const Icon(
                        Icons.equalizer_outlined,
                        color: Colors.blueGrey,
                        size: 16,
                      ),
                      const SizedBox(
                        width: 2,
                      ),
                      Text(
                        TranslationKey.autoCleanFrequency.tr,
                        style: const TextStyle(color: Colors.blueGrey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Obx(
                    () => CupertinoSegmentedControl(
                      //子标签
                      children: controller.freqSegmented,
                      //当前选中的索引
                      groupValue: controller.frequency.value,
                      //点击回调
                      onValueChanged: (index) {
                        controller.frequency.value = index;
                        controller.updateNextExecTime();
                      },
                    ),
                  ),
                  const SizedBox(height: 4),

                  ///endregion

                  ///region 执行时间
                  Row(
                    children: [
                      const Icon(
                        Icons.timer,
                        color: Colors.blueGrey,
                        size: 16,
                      ),
                      const SizedBox(
                        width: 2,
                      ),
                      Text(
                        TranslationKey.execTime.tr,
                        style: const TextStyle(color: Colors.blueGrey),
                      ),
                    ],
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Obx(
                      () => Visibility(
                        visible: controller.frequency.value == CleanDataFreq.cron,
                        replacement: Row(
                          children: [
                            Visibility(
                              visible: controller.frequency.value == CleanDataFreq.week,
                              child: RawChip(
                                label: Text(controller.selectedWeekDay.value?.label ?? WeekDay.monday.label),
                                onPressed: () {
                                  controller.showWeekDaySelectDialog();
                                },
                                visualDensity: const VisualDensity(
                                  horizontal: VisualDensity.minimumDensity,
                                  vertical: VisualDensity.minimumDensity,
                                ),
                                labelPadding: EdgeInsets.zero,
                              ),
                            ),
                            Visibility(
                              visible: controller.frequency.value == CleanDataFreq.week,
                              child: const SizedBox(
                                width: 10,
                              ),
                            ),
                            RawChip(
                              label: Text("${controller.selectedHour} h : ${controller.selectedMinute} min"),
                              onPressed: () {
                                controller.showTimeSelectDialog();
                              },
                              visualDensity: const VisualDensity(
                                horizontal: VisualDensity.minimumDensity,
                                vertical: VisualDensity.minimumDensity,
                              ),
                              labelPadding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: controller.cronInputCtl,
                          decoration: InputDecoration(
                            label: Text("${TranslationKey.pleaseInput.tr} UnixCron"),
                            border: const OutlineInputBorder(),
                            suffixIcon: const Icon(
                              Icons.timer,
                              color: Colors.blueGrey,
                            ),
                          ),
                          onChanged: (v) {
                            controller.updateNextExecTime();
                          },
                        ),
                      ),
                    ),
                  ),
                  Obx(
                    () => Visibility(
                      visible: controller.nextExecTime.value != null,
                      replacement: Container(
                        color: const Color(0xD4FBE7DC),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [Expanded(child: Text(TranslationKey.errorCronTips.tr))],
                          ),
                        ),
                      ),
                      child: Container(
                        color: const Color(0xD4E9F3FF),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Text(TranslationKey.nextExecTime.tr),
                              Text(
                                controller.nextExecTime.value ?? "",
                                style: const TextStyle(
                                  color: Colors.blueAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  ///endregion

                  ///region 操作按钮
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      controller.saveAutoCleanConfig();
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.save,
                          size: 16,
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        Text(TranslationKey.saveAutoCleanConfig.tr),
                      ],
                    ),
                  ),

                  ///endregion
                ],
              ),
            ),
          ),
        ],
      ),
    );
    if (showAppBar) {
      return Scaffold(
        appBar: showAppBar
            ? AppBar(
                title: Text(TranslationKey.cleanData.tr),
                backgroundColor: currentTheme.colorScheme.inversePrimary,
              )
            : null,
        body: SafeArea(child: content),
      );
    }
    return Card(
      color: Theme.of(context).cardTheme.color,
      elevation: 0,
      margin: const EdgeInsets.all(8),
      child: content,
    );
  }
}
