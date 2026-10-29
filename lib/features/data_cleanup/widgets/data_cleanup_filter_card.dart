import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:clipshare/core/database/tables/device.dart';
import 'package:clipshare/core/models/local_app_info.dart';
import 'package:clipshare/core/services/clipboard/clipboard_source_provider.dart';
import 'package:clipshare/core/services/device/device_provider.dart';
import 'package:clipshare/features/app_selection/app_selection_entry.dart';
import 'package:clipshare/features/app_selection/widgets/app_info_groups_view.dart';
import 'package:clipshare/features/data_cleanup/providers/data_cleanup_page_provider.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/enums/history_content_type.dart';
import 'package:clipshare/shared/extensions/number_extension.dart';
import 'package:clipshare/shared/extensions/string_extension.dart';
import 'package:clipshare/shared/extensions/time_extension.dart';
import 'package:clipshare/shared/models/dialog_actions.dart';
import 'package:clipshare/shared/utils/dialog.dart';
import 'package:clipshare/shared/utils/snackbar.dart';
import 'package:clipshare/shared/widgets/base/condition_widget.dart';
import 'package:clipshare/shared/widgets/base/empty_content.dart';
import 'package:clipshare/shared/widgets/base/rounded_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 数据清理的过滤器卡片：标签/设备/来源/日期/内容类型筛选与清理操作。
class DataCleanupFilterCard extends ConsumerStatefulWidget {
  const DataCleanupFilterCard({super.key});

  @override
  ConsumerState<DataCleanupFilterCard> createState() => _DataCleanupFilterCardState();
}

class _DataCleanupFilterCardState extends ConsumerState<DataCleanupFilterCard> {
  /// 保留天数输入控制器
  late final TextEditingController saveDaysController;

  @override
  void initState() {
    super.initState();
    final saveDays = ref.read(dataCleanupPageProvider).saveDays;
    saveDaysController = TextEditingController(text: saveDays == 0 ? '' : saveDays.toString());
  }

  @override
  void dispose() {
    saveDaysController.dispose();
    super.dispose();
  }

  /// 加载设备显示名，未存储时回退为“未知”
  String _getDevNameById(String devId) {
    final deviceState = ref.read(deviceProvider).requireValue;
    return deviceState.getStoredName(devId) ?? TranslationKey.unknown.tr;
  }

  /// 打开来源（应用）选择入口
  void _openAppSelection() {
    final notifier = ref.read(dataCleanupPageProvider.notifier);
    final state = ref.read(dataCleanupPageProvider);
    final appInfos = ref.read(clipboardSourceProvider).requireValue.appInfos;
    showAppSelection(
      context,
      AppSelectionRouteArgs(
        loadDeviceName: _getDevNameById,
        selectedIds: state.selectedSources,
        loadAppInfos: () {
          final list = appInfos.map((item) => LocalAppInfo.fromAppInfo(item, false)).toList();
          return Future<List<LocalAppInfo>>.value(list);
        },
        onSelectedDone: (selected) {
          notifier.addSources(selected.map((item) => item.appId));
        },
      ),
    );
  }

  /// 清理前统计命中数量并弹确认框
  Future<void> _confirmAndClean() async {
    final notifier = ref.read(dataCleanupPageProvider.notifier);
    final cnt = await notifier.countByFilter();
    if (!mounted) {
      return;
    }
    if (cnt == 0) {
      snackbar.success(context, TranslationKey.noDataFromFilter.tr);
      return;
    }
    dialogManager.tips(
      context,
      text: TranslationKey.filterCleaningConfirmation.trParams({'cnt': cnt.toString()}),
      actions: DialogActions(
        cancel: const DialogAction(),
        confirm: DialogAction(
          onPressed: () {
            // 确认按钮在弹窗交互后才触发，需再次校验页面是否仍在
            if (!mounted) {
              return;
            }
            notifier.cleanData(context);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dataCleanupPageProvider);
    final notifier = ref.read(dataCleanupPageProvider.notifier);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    const sectionColor = Colors.blueGrey;
    const chipLabelStyle = TextStyle(fontSize: 12);
    final filterChipSelectedColor = colorScheme.primaryContainer;
    final filterChipCheckmarkColor = colorScheme.onPrimaryContainer;
    final appInfos = ref.watch(clipboardSourceProvider).requireValue.appInfos;
    final selectedApps = appInfos.where((app) => state.selectedSources.contains(app.appId)).toList();

    return Card(
      color: theme.cardTheme.color,
      elevation: 0,
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //region 过滤器标题
            Row(
              children: [
                const Icon(Icons.filter_alt_rounded, color: sectionColor, size: 20),
                const SizedBox(width: 5),
                Text(
                  TranslationKey.filter.tr,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: sectionColor),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    dialogManager.tips(context, text: TranslationKey.filterTips.tr);
                  },
                  icon: const Icon(Icons.info_outline, color: sectionColor, size: 18),
                ),
              ],
            ),

            //endregion

            //region 标签过滤
            Row(
              children: [
                const Icon(Icons.tag, color: sectionColor, size: 16),
                const SizedBox(width: 2),
                Text(TranslationKey.filterByTag.tr, style: const TextStyle(color: sectionColor)),
              ],
            ),
            const SizedBox(height: 4),
            Visibility(
              visible: state.allTags.isNotEmpty,
              replacement: const Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [EmptyContent(size: 40, showText: false)],
              ),
              child: Wrap(
                direction: Axis.horizontal,
                children: [
                  for (var tag in state.allTags)
                    Container(
                      margin: const EdgeInsets.only(right: 5, bottom: 5),
                      child: RoundedChip(
                        onPressed: () {
                          notifier.toggleTag(tag);
                        },
                        selected: state.selectedTags.contains(tag),
                        labelStyle: chipLabelStyle,
                        selectedColor: filterChipSelectedColor,
                        checkmarkColor: filterChipCheckmarkColor,
                        label: Text(tag),
                      ),
                    ),
                ],
              ),
            ),

            //endregion

            //region 设备过滤
            Row(
              children: [
                const Icon(Icons.devices_outlined, color: sectionColor, size: 16),
                const SizedBox(width: 2),
                Text(TranslationKey.filterByDevice.tr, style: const TextStyle(color: sectionColor)),
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              direction: Axis.horizontal,
              children: [
                for (var dev in state.allDevices)
                  Container(
                    margin: const EdgeInsets.only(right: 5, bottom: 5),
                    child: RoundedChip(
                      onPressed: () {
                        notifier.toggleDev(dev.guid);
                      },
                      selected: state.selectedDevs.contains(dev.guid),
                      labelStyle: chipLabelStyle,
                      selectedColor: filterChipSelectedColor,
                      checkmarkColor: filterChipCheckmarkColor,
                      label: Text(dev.displayName),
                    ),
                  ),
              ],
            ),

            //endregion

            //region 来源过滤
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(MdiIcons.listBoxOutline, color: sectionColor, size: 16),
                      const SizedBox(width: 2),
                      Text(TranslationKey.filterBySource.tr, style: const TextStyle(color: sectionColor)),
                    ],
                  ),
                ),
                RoundedChip(
                  avatar: const Icon(Icons.add, color: sectionColor),
                  labelStyle: chipLabelStyle,
                  label: Text(TranslationKey.selection.tr),
                  onPressed: _openAppSelection,
                ),
              ],
            ),
            const SizedBox(height: 4),
            AppInfoGroupsView(
              appInfos: selectedApps,
              onPress: (app) {
                notifier.toggleSource(app.appId);
              },
              loadDevName: _getDevNameById,
            ),

            //endregion

            //region 日期过滤
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.date_range, color: sectionColor, size: 16),
                      const SizedBox(width: 2),
                      Text(TranslationKey.filterByDate.tr, style: const TextStyle(color: sectionColor)),
                    ],
                  ),
                ),
                RoundedChip(
                  labelStyle: chipLabelStyle,
                  label: Text(TranslationKey.retainDays.tr),
                  selectedColor: filterChipSelectedColor,
                  checkmarkColor: filterChipCheckmarkColor,
                  onSelected: (selected) {
                    notifier.setUseDaysFilter(selected);
                  },
                  selected: state.useDaysFilter,
                ),
              ],
            ),
            const SizedBox(height: 4),
            ConditionWidget(
              visible: state.useDaysFilter,
              replacement: Container(
                margin: 10.insetB,
                child: Row(
                  children: [
                    RoundedChip(
                      onPressed: () => _showDateRangeSelectDialog(),
                      label: Text(
                        state.startDate ?? TranslationKey.startDate.tr,
                        style: const TextStyle(color: sectionColor),
                      ),
                      avatar: const Icon(Icons.date_range_outlined, color: sectionColor),
                      labelStyle: chipLabelStyle,
                      deleteIcon: Visibility(
                        visible: state.startDate == null,
                        replacement: const Icon(Icons.close, size: 17, color: Colors.blue),
                        child: const Icon(Icons.location_on, size: 17, color: Colors.blue),
                      ),
                      deleteButtonTooltipMessage: state.startDate == null ? TranslationKey.toToday.tr : TranslationKey.clear.tr,
                      onDeleted: () {
                        if (state.startDate == null) {
                          notifier.setStartDate(DateTime.now().format('yyyy-MM-dd'));
                        } else {
                          notifier.setStartDate(null);
                        }
                      },
                    ),
                    Container(
                      margin: const EdgeInsets.only(right: 10, left: 10),
                      child: const Text('-'),
                    ),
                    RoundedChip(
                      onPressed: () => _showDateRangeSelectDialog(),
                      label: Text(
                        state.endDate ?? TranslationKey.endDate.tr,
                        style: const TextStyle(color: sectionColor),
                      ),
                      avatar: const Icon(Icons.date_range_outlined, color: sectionColor),
                      labelStyle: chipLabelStyle,
                      deleteIcon: Visibility(
                        visible: state.endDate == null,
                        replacement: const Icon(Icons.close, size: 17, color: Colors.blue),
                        child: const Icon(Icons.location_on, size: 17, color: Colors.blue),
                      ),
                      deleteButtonTooltipMessage: state.endDate == null ? TranslationKey.toToday.tr : TranslationKey.clear.tr,
                      onDeleted: () {
                        if (state.endDate == null) {
                          notifier.setEndDate(DateTime.now().format('yyyy-MM-dd'));
                        } else {
                          notifier.setEndDate(null);
                        }
                      },
                    ),
                  ],
                ),
              ),
              child: TextField(
                controller: saveDaysController,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: TranslationKey.retainDays.tr,
                  isDense: true,
                  suffixText: TranslationKey.day.tr,
                ),
                autofocus: true,
                onChanged: (dayStr) {
                  notifier.updateSaveDays(dayStr.toInt());
                },
                keyboardType: TextInputType.number,
                inputFormatters: [
                  // 限制只能输入数字
                  FilteringTextInputFormatter.digitsOnly,
                ],
              ),
            ),

            //endregion

            //region 内容类型过滤
            Row(
              children: [
                const Icon(Icons.category, color: sectionColor, size: 16),
                const SizedBox(width: 2),
                Text(TranslationKey.filterByContentType.tr, style: const TextStyle(color: sectionColor)),
              ],
            ),
            const SizedBox(height: 4),
            SingleChildScrollView(
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
                          selected: state.selectedContentTypes.contains(type),
                          onPressed: () {
                            notifier.toggleContentType(type);
                          },
                          labelStyle: chipLabelStyle,
                          selectedColor: theme.chipTheme.selectedColor ?? filterChipSelectedColor,
                          checkmarkColor: filterChipCheckmarkColor,
                          label: Text(type.label),
                        ),
                        const SizedBox(width: 5),
                      ],
                    ),
                ],
              ),
            ),

            //endregion

            //region 可选项
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(TranslationKey.saveTopData.tr, style: const TextStyle(fontSize: 16)),
                Switch(
                  value: state.saveTopData,
                  onChanged: (checked) {
                    HapticFeedback.mediumImpact();
                    notifier.setSaveTopData(checked);
                  },
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(TranslationKey.removeLocalFiles.tr, style: const TextStyle(fontSize: 16)),
                Switch(
                  value: state.removeFiles,
                  onChanged: (checked) {
                    HapticFeedback.mediumImpact();
                    notifier.setRemoveFiles(checked);
                  },
                ),
              ],
            ),

            //endregion

            //region 操作按钮
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      notifier.saveFilterConfig(context);
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.save, size: 16),
                        const SizedBox(width: 5),
                        Text(TranslationKey.saveFilterConfig.tr),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: _confirmAndClean,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.clear_all_outlined),
                        const SizedBox(width: 5),
                        Text(TranslationKey.dataCleanup.tr),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                dialogManager.tips(
                  context,
                  text: TranslationKey.syncRecordsCleaningConfirmation.tr,
                  actions: DialogActions(
                    cancel: const DialogAction(),
                    confirm: DialogAction(onPressed: () => notifier.cleanDeviceSyncRecords(context)),
                  ),
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.notification_important_outlined, size: 16, color: Colors.deepOrange),
                  const SizedBox(width: 5),
                  Text(
                    TranslationKey.syncRecordsCleanBtn.tr,
                    style: const TextStyle(color: Colors.deepOrange),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                dialogManager.tips(
                  context,
                  text: TranslationKey.optionRecordsCleaningConfirmation.tr,
                  actions: DialogActions(
                    cancel: const DialogAction(),
                    confirm: DialogAction(onPressed: () => notifier.cleanDeviceOperationRecords(context)),
                  ),
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.notification_important_outlined, size: 16, color: Colors.deepOrange),
                  const SizedBox(width: 5),
                  Text(
                    TranslationKey.optionRecordsCleanBtn.tr,
                    style: const TextStyle(color: Colors.deepOrange),
                  ),
                ],
              ),
            ),

            //endregion
          ],
        ),
      ),
    );
  }

  /// 选择日期范围
  Future<void> _showDateRangeSelectDialog() async {
    final notifier = ref.read(dataCleanupPageProvider.notifier);
    //显示日期选择器
    var range = await showCalendarDatePicker2Dialog(
      context: context,
      config: CalendarDatePicker2WithActionButtonsConfig(
        calendarType: CalendarDatePicker2Type.range,
      ),
      dialogSize: const Size(325, 400),
      borderRadius: BorderRadius.circular(15),
    );
    if (range != null) {
      notifier.setStartDate(range[0]!.format('yyyy-MM-dd'));
      notifier.setEndDate(range[1]!.format('yyyy-MM-dd'));
    }
  }
}
