import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/models/local_app_info.dart';
import 'package:clipshare/app/data/models/search_filter.dart';
import 'package:clipshare/app/data/repository/entity/tables/app_info.dart';
import 'package:clipshare/app/modules/views/app_selection_page.dart';
import 'package:clipshare/app/utils/extensions/list_extension.dart';
import 'package:clipshare/app/utils/extensions/time_extension.dart';
import 'package:clipshare/app/widgets/condition_widget.dart';
import 'package:clipshare/app/widgets/dynamic_size_widget.dart';
import 'package:clipshare/app/widgets/empty_content.dart';
import 'package:clipshare/app/widgets/rounded_chip.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'history_filter.dart';

class FilterDetail extends StatelessWidget {
  final HistoryFilterController controller;
  final void Function(SearchFilter filter) onConfirm;
  static final emptyContent = EmptyContent(size: 40);
  final bold18Style = const TextStyle(fontSize: 18, fontWeight: FontWeight.bold);

  const FilterDetail({
    super.key,
    required this.controller,
    required this.onConfirm,
  });

  void onDateRangeClick() async {
    //显示时间选择器
    var range = await showCalendarDatePicker2Dialog(
      context: Get.context!,
      config: CalendarDatePicker2WithActionButtonsConfig(calendarType: CalendarDatePicker2Type.range),
      dialogSize: const Size(325, 400),
      borderRadius: BorderRadius.circular(15),
    );
    if (range != null) {
      controller.startDate.value = range[0]!.format("yyyy-MM-dd");
      controller.endDate.value = range[1]!.format("yyyy-MM-dd");
    }
  }

  @override
  Widget build(BuildContext context) {
    final confirmBtn = TextButton(
      onPressed: () {
        onConfirm(controller.filter);
      },
      child: Text(TranslationKey.confirm.tr),
    );
    final header = Row(
      children: [
        Expanded(
          child: Row(
            children: [
              const Icon(Icons.filter_alt_rounded, color: Colors.blueGrey, size: 20),
              const SizedBox(width: 5),
              Text(TranslationKey.filter.tr, style: bold18Style.copyWith(color: Colors.blueGrey)),
            ],
          ),
        ),
        Row(
          children: [
            Row(
              children: [
                TextButton.icon(
                  icon: Obx(() => Icon(controller.onlyNoSync.value ? Icons.check_box : Icons.check_box_outline_blank_sharp)),
                  label: Text(TranslationKey.onlyNotSync.tr),
                  onPressed: () {
                    controller.onlyNoSync.value = !controller.onlyNoSync.value;
                  },
                ),
              ],
            ),
            Visibility(visible: !controller.isBigScreen, child: confirmBtn),
          ],
        ),
      ],
    );
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        //region 筛选日期 label
        Container(
          margin: const EdgeInsets.only(bottom: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [Text(TranslationKey.filterByDate.tr, style: bold18Style)],
          ),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            Obx(
              () => RoundedChip(
                onPressed: onDateRangeClick,
                label: Obx(() => Text(controller.startDateStr, style: TextStyle(color: controller.startDate.value == "" && controller.startDateStr == TranslationKey.startDate.tr ? Colors.blueGrey : null))),
                avatar: const Icon(Icons.date_range_outlined),
                deleteIcon: Obx(() => Icon(controller.startDateStr != controller.nowDayStr || controller.startDateStr == TranslationKey.startDate.tr ? Icons.location_on : Icons.close, size: 17, color: Colors.blue)),
                deleteButtonTooltipMessage: controller.startDateStr != controller.nowDayStr || controller.startDateStr == TranslationKey.startDate.tr ? TranslationKey.toToday.tr : TranslationKey.clear.tr,
                onDeleted: controller.startDateStr != controller.nowDayStr
                    ? () {
                        controller.startDate.value = DateTime.now().toString().substring(0, 10);
                      }
                    : () {
                        controller.startDate.value = "";
                      },
              ),
            ),
            Container(margin: const EdgeInsets.only(right: 10, left: 10), child: const Text("-")),
            Obx(
              () => RoundedChip(
                onPressed: onDateRangeClick,
                label: Obx(() => Text(controller.endDateStr, style: TextStyle(color: controller.endDate.value == "" && controller.endDateStr == TranslationKey.endDate.tr ? Colors.blueGrey : null))),
                avatar: const Icon(Icons.date_range_outlined),
                deleteIcon: Obx(() => Icon(controller.endDateStr != controller.nowDayStr || controller.endDateStr == TranslationKey.endDate.tr ? Icons.location_on : Icons.close, size: 17, color: Colors.blue)),
                deleteButtonTooltipMessage: controller.endDateStr != controller.nowDayStr || controller.endDateStr == TranslationKey.endDate.tr ? TranslationKey.toToday.tr : TranslationKey.clear.tr,
                onDeleted: controller.endDateStr != controller.nowDayStr || controller.endDateStr == TranslationKey.endDate.tr
                    ? () {
                        controller.endDate.value = DateTime.now().toString().substring(0, 10);
                      }
                    : () {
                        controller.endDate.value = "";
                      },
              ),
            ),
          ],
        ),
        //endregion

        //region 筛选设备
        Row(
          children: <Widget>[
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 10),
              child: Text(TranslationKey.filterByDevice.tr, style: bold18Style),
            ),
            const SizedBox(width: 5),
            Obx(
              () => Visibility(
                visible: controller.selectedDevIds.isNotEmpty,
                child: SizedBox(
                  height: 25,
                  width: 25,
                  child: IconButton(
                    padding: const EdgeInsets.all(2),
                    tooltip: TranslationKey.clear.tr,
                    iconSize: 13,
                    color: Colors.blueGrey,
                    onPressed: () {
                      controller.selectedDevIds.clear();
                    },
                    icon: const Icon(Icons.cleaning_services_sharp),
                  ),
                ),
              ),
            ),
          ],
        ),
        Obx(() => Visibility(visible: controller.allDevices.isEmpty, child: emptyContent)),
        const SizedBox(height: 5),
        Obx(
          () => Wrap(
            direction: Axis.horizontal,
            children: [
              for (var dev in controller.allDevices)
                Obx(
                  () => Container(
                    margin: const EdgeInsets.only(right: 5, bottom: 5),
                    child: RoundedChip(
                      onPressed: () {
                        var guid = dev.guid;
                        if (controller.selectedDevIds.contains(guid)) {
                          controller.selectedDevIds.remove(guid);
                        } else {
                          controller.selectedDevIds.add(guid);
                        }
                      },
                      selected: controller.selectedDevIds.contains(dev.guid),
                      label: Text(dev.name),
                    ),
                  ),
                ),
            ],
          ),
        ),
        //endregion

        //region 筛选标签
        Row(
          children: <Widget>[
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 10),
              child: Text(TranslationKey.filterByTag.tr, style: bold18Style),
            ),
            const SizedBox(width: 5),
            Obx(
              () => Visibility(
                visible: controller.selectedTags.isNotEmpty,
                child: SizedBox(
                  height: 25,
                  width: 25,
                  child: IconButton(
                    padding: const EdgeInsets.all(2),
                    tooltip: TranslationKey.clear.tr,
                    iconSize: 13,
                    color: Colors.blueGrey,
                    onPressed: () {
                      controller.selectedTags.clear();
                    },
                    icon: const Icon(Icons.cleaning_services_sharp),
                  ),
                ),
              ),
            ),
          ],
        ),
        Obx(() => Visibility(visible: controller.allTagNames.isEmpty, child: emptyContent)),
        const SizedBox(height: 5),
        Obx(
          () => Wrap(
            direction: Axis.horizontal,
            children: [
              for (var tag in controller.allTagNames)
                Container(
                  margin: const EdgeInsets.only(right: 5, bottom: 5),
                  child: Obx(
                    () => RoundedChip(
                      onPressed: () {
                        if (controller.selectedTags.contains(tag)) {
                          controller.selectedTags.remove(tag);
                        } else {
                          controller.selectedTags.add(tag);
                        }
                      },
                      selected: controller.selectedTags.contains(tag),
                      label: Text(tag),
                    ),
                  ),
                ),
            ],
          ),
        ),
        //endregion

        //region 筛选来源
        Row(
          children: <Widget>[
            Expanded(
              child: Row(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 10),
                    child: Text(TranslationKey.filterBySource.tr, style: bold18Style),
                  ),
                  const SizedBox(width: 5),
                  Obx(
                    () => Visibility(
                      visible: controller.selectedAppIds.isNotEmpty,
                      child: SizedBox(
                        height: 25,
                        width: 25,
                        child: IconButton(
                          padding: const EdgeInsets.all(2),
                          tooltip: TranslationKey.clear.tr,
                          iconSize: 13,
                          color: Colors.blueGrey,
                          onPressed: () {
                            controller.selectedAppIds.clear();
                          },
                          icon: const Icon(Icons.cleaning_services_sharp),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            RoundedChip(
              avatar: const Icon(Icons.add),
              label: Text(TranslationKey.selection.tr),
              onPressed: () {
                final page = AppSelectionPage(
                  loadDeviceName: controller.getDevNameById,
                  selectedIds: controller.selectedAppIds,
                  loadAppInfos: () {
                    final list = controller.allSources.map((item) => LocalAppInfo.fromAppInfo(item, false)).toList();
                    return Future<List<LocalAppInfo>>.value(list);
                  },
                  onSelectedDone: (selected) {
                    controller.selectedAppIds.addAll(selected.map((item) => item.appId));
                  },
                );
                if (!controller.isBigScreen) {
                  Get.to(page);
                } else {
                  Get.dialog(DynamicSizeWidget(child: page));
                }
              },
            ),
          ],
        ),
        Obx(() => Visibility(visible: controller.allSources.isEmpty, child: emptyContent)),
        const SizedBox(height: 5),
        Obx(() {
          final selectedAppIds = controller.selectedAppIds;
          final selectedApps = controller.allSources.where((app) => selectedAppIds.contains(app.appId)).toList();
          final groups = selectedApps.groupBy((item) => item.devId);
          if (selectedApps.isEmpty) {
            return emptyContent;
          }
          return Column(
            children: groups.keys.map((devId) {
              final appList = groups[devId]!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsetsGeometry.only(bottom: 8),
                    child: DefaultTextStyle(
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                      child: Row(
                        children: [
                          const Text("#"),
                          const SizedBox(width: 5),
                          Text(
                            controller.getDevNameById(devId),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Wrap(
                    direction: Axis.horizontal,
                    children: [
                      for (var app in appList)
                        Container(
                          margin: const EdgeInsets.only(right: 5, bottom: 5),
                          child: RoundedChip(
                            onPressed: () {
                              if (controller.selectedAppIds.contains(app.appId)) {
                                controller.selectedAppIds.remove(app.appId);
                              } else {
                                controller.selectedAppIds.add(app.appId);
                              }
                            },
                            selected: true,
                            label: Text(app.name),
                            avatar: Image.memory(app.iconBytes),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            }).toList(),
          );
        }),
        //endregion
      ],
    );
    const padding = EdgeInsets.all(8);
    //这里不能使用visibility，否则会导致 RoundedChip 的背景色失效
    return ConditionWidget(
      visible: controller.isBigScreen,
      replacement: Container(
        padding: padding,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 300),
          child: Column(
            children: [
              header,
              Expanded(child: SingleChildScrollView(child: body)),
            ],
          ),
        ),
      ),
      child: Card(
        color: Theme.of(context).cardTheme.color,
        elevation: 0,
        margin: padding,
        child: Container(
          padding: padding,
          child: Column(
            children: [
              header,
              Expanded(child: SingleChildScrollView(child: body)),
              SizedBox(width: 150, child: confirmBtn),
            ],
          ),
        ),
      ),
    );
  }
}
