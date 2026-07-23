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
import 'package:clipshare/app/utils/extensions/number_extension.dart';
import 'package:clipshare/app/utils/extensions/string_extension.dart';
import 'package:clipshare/app/utils/extensions/time_extension.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/widgets/clip/app_icon.dart';
import 'package:clipshare/app/widgets/app_info_groups_view.dart';
import 'package:clipshare/app/widgets/base/tiny_segmented_control.dart';
import 'package:clipshare/app/widgets/condition_widget.dart';
import 'package:clipshare/app/widgets/dynamic_size_widget.dart';
import 'package:clipshare/app/widgets/rounded_chip.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
/**
 * GetX Template Generator - fb.com/htngu.99
 * */

class CleanDataPage extends GetView<CleanDataController> {
  final sourceService = Get.find<ClipboardSourceService>();
  final devService = Get.find<DeviceService>();
  final appConfig = Get.find<ConfigService>();

  @override
  Widget build(BuildContext context) {
    final appConfig = Get.find<ConfigService>();
    final dbService = Get.find<DbService>();
    final showAppBar = appConfig.isSmallScreen;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final sectionColor = colorScheme.onSurfaceVariant;
    final chipSide = BorderSide(color: colorScheme.outlineVariant);
    final chipLabelStyle = TextStyle(color: colorScheme.onSurfaceVariant);
    final filterChipSelectedColor = colorScheme.primaryContainer;
    final filterChipCheckmarkColor = colorScheme.onPrimaryContainer;
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
                      Icon(
                        Icons.filter_alt_rounded,
                        color: sectionColor,
                        size: 20,
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      Text(
                        TranslationKey.filter.tr,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: sectionColor,
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          Global.showTipsDialog(context: Get.context!, text: TranslationKey.filterTips.tr);
                        },
                        icon: Icon(
                          Icons.info_outline,
                          color: sectionColor,
                          size: 18,
                        ),
                      ),
                    ],
                  ),

                  ///endregion

                  ///region 标签过滤
                  Row(
                    children: [
                      Icon(
                        Icons.tag,
                        color: sectionColor,
                        size: 16,
                      ),
                      const SizedBox(
                        width: 2,
                      ),
                      Text(
                        TranslationKey.filterByTag.tr,
                        style: TextStyle(color: sectionColor),
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
                                  side: chipSide,
                                  selectedColor: filterChipSelectedColor,
                                  checkmarkColor: filterChipCheckmarkColor,
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
                      Icon(
                        Icons.devices_outlined,
                        color: sectionColor,
                        size: 16,
                      ),
                      const SizedBox(
                        width: 2,
                      ),
                      Text(
                        TranslationKey.filterByDevice.tr,
                        style: TextStyle(color: sectionColor),
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
                            side: chipSide,
                            selectedColor: filterChipSelectedColor,
                            checkmarkColor: filterChipCheckmarkColor,
                            label: Text(dev.displayName),
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
                              color: sectionColor,
                              size: 16,
                            ),
                            const SizedBox(
                              width: 2,
                            ),
                            Text(
                              TranslationKey.filterBySource.tr,
                              style: TextStyle(color: sectionColor),
                            ),
                          ],
                        ),
                      ),
                      RoundedChip(
                        avatar: Icon(Icons.add, color: sectionColor),
                        side: chipSide,
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
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.date_range,
                              color: sectionColor,
                              size: 16,
                            ),
                            const SizedBox(
                              width: 2,
                            ),
                            Text(
                              TranslationKey.filterByDate.tr,
                              style: TextStyle(color: sectionColor),
                            ),
                          ],
                        ),
                      ),
                      Obx(
                        () => RoundedChip(
                          label: Text(TranslationKey.retainDays.tr),
                          side: chipSide,
                          selectedColor: filterChipSelectedColor,
                          checkmarkColor: filterChipCheckmarkColor,
                          onSelected: (selected) {
                            controller.useDaysFilter.value = selected;
                          },
                          selected: controller.useDaysFilter.value,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  Obx(
                    () => ConditionWidget(
                      visible: controller.useDaysFilter.value,
                      replacement: Container(
                        margin: 10.insetB,
                        child: Row(
                          children: [
                            Obx(
                              () => RoundedChip(
                                onPressed: controller.showDateRangeSelectDialog,
                                label: Obx(
                                  () => Text(
                                    controller.startDate.value ?? TranslationKey.startDate.tr,
                                    style: TextStyle(
                                      color: sectionColor,
                                    ),
                                  ),
                                ),
                                avatar: Icon(Icons.date_range_outlined, color: sectionColor),
                                side: chipSide,
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
                                    style: TextStyle(
                                      color: sectionColor,
                                    ),
                                  ),
                                ),
                                avatar: Icon(Icons.date_range_outlined, color: sectionColor),
                                side: chipSide,
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
                      ),
                      child: TextField(
                        controller: controller.saveDaysController,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          labelText: TranslationKey.retainDays.tr,
                          isDense: true,
                          suffixText: TranslationKey.day.tr,
                        ),
                        autofocus: true,
                        onChanged: (dayStr) {
                          controller.saveDays.value = dayStr.toInt();
                        },
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          // 限制只能输入数字
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ),
                  ),

                  ///endregion

                  ///region 内容类型过滤
                  Row(
                    children: [
                      Icon(
                        Icons.category,
                        color: sectionColor,
                        size: 16,
                      ),
                      const SizedBox(
                        width: 2,
                      ),
                      Text(
                        TranslationKey.filterByContentType.tr,
                        style: TextStyle(color: sectionColor),
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
                                  side: chipSide,
                                  selectedColor: theme.chipTheme.selectedColor ?? filterChipSelectedColor,
                                  checkmarkColor: filterChipCheckmarkColor,
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
                            String? startTime = controller.startDate.value;
                            String? endTime = controller.endDate.value;
                            //如果启用了天数过滤，则删除指定天数前的数据
                            if(controller.useDaysFilter.value){
                              final now = DateTime.now();
                              startTime = '1970-01-01';
                              endTime = now.add(Duration(days: -1 * controller.saveDays.value)).format('yyyy-MM-dd');
                            }
                            final cnt = await dbService.historyDao.count(
                                  appConfig.userId,
                                  controller.selectedContentTypes.map((item) => item.value).toList(),
                                  controller.selectedTags.toList(),
                                  controller.selectedDevs.toList(),
                                  controller.selectedSources.toList(),
                                  startTime ?? "",
                                  endTime ?? "",
                                  controller.saveTopData.value,
                                ) ?? 0;
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ///region 标题
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.timer,
                            color: sectionColor,
                            size: 20,
                          ),
                          const SizedBox(
                            width: 5,
                          ),
                          Text(
                            TranslationKey.autoCleanConfigTitle.tr,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: sectionColor),
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
                      Icon(
                        Icons.equalizer_outlined,
                        color: sectionColor,
                        size: 16,
                      ),
                      const SizedBox(
                        width: 2,
                      ),
                      Text(
                        TranslationKey.autoCleanFrequency.tr,
                        style: TextStyle(color: sectionColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Builder(builder: (ctx) {
                    final freqs = [CleanDataFreq.day, CleanDataFreq.week, CleanDataFreq.cron];
                    final labels = [TranslationKey.daily.tr, TranslationKey.weekly.tr, "Cron"];
                    return TinySegmentedControl.fromStrings(
                      options: labels,
                      onSelected: (int index) {
                        final freq = freqs[index];
                        controller.frequency.value = freq;
                        controller.updateNextExecTime();
                      },
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      selectedColor: colorScheme.onPrimaryContainer,
                      selectedBackgroundColor: colorScheme.primaryContainer,
                      unselectedColor: colorScheme.onSurfaceVariant,
                      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    );
                  }),
                  const SizedBox(height: 4),

                  ///endregion

                  ///region 执行时间
                  Row(
                    children: [
                      Icon(
                        Icons.timer,
                        color: sectionColor,
                        size: 16,
                      ),
                      const SizedBox(
                        width: 2,
                      ),
                      Text(
                        TranslationKey.execTime.tr,
                        style: TextStyle(color: sectionColor),
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
                                labelStyle: chipLabelStyle,
                                side: chipSide,
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
                              labelStyle: chipLabelStyle,
                              side: chipSide,
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
                            suffixIcon: Icon(
                              Icons.timer,
                              color: sectionColor,
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
                        color: colorScheme.errorContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  TranslationKey.errorCronTips.tr,
                                  style: TextStyle(color: colorScheme.onErrorContainer),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      child: Container(
                        color: colorScheme.primaryContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Text(
                                TranslationKey.nextExecTime.tr,
                                style: TextStyle(color: colorScheme.onPrimaryContainer),
                              ),
                              Text(
                                controller.nextExecTime.value ?? "",
                                style: TextStyle(
                                  color: colorScheme.onPrimaryContainer,
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
