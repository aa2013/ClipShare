import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:clipshare/core/database/tables/app_info.dart';
import 'package:clipshare/core/database/tables/device.dart';
import 'package:clipshare/core/extensions/context_extension.dart';
import 'package:clipshare/core/utils/dialog.dart';
import 'package:clipshare/features/app_selection/models/local_app_info.dart';
import 'package:clipshare/features/app_selection/pages/app_selection_page.dart';
import 'package:clipshare/features/app_selection/widgets/app_info_groups_view.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/extensions/time_extension.dart';
import 'package:clipshare/shared/models/search_filter.dart';
import 'package:clipshare/shared/widgets/base/condition_widget.dart';
import 'package:clipshare/shared/widgets/base/empty_content.dart';
import 'package:clipshare/shared/widgets/base/rounded_chip.dart';
import 'package:flutter/material.dart';

/// 更多筛选详情面板：日期范围、设备、标签、来源筛选。
///
/// 受控纯 widget：根据 [value] 与筛选数据源渲染，条件变化通过 [onChanged] 上报。
class FilterDetail extends StatelessWidget {
  /// 当前筛选条件。
  final SearchFilter value;

  /// 可筛选设备（本机在前）。
  final List<Device> devices;

  /// 全部标签名。
  final List<String> tags;

  /// 全部来源（应用）信息。
  final List<AppInfo> sources;

  /// 条件变化回调。
  final ValueChanged<SearchFilter> onChanged;

  /// 确认回调（点击确认按钮时触发）。
  final VoidCallback onConfirm;

  static const emptyContent = EmptyContent(size: 40);
  final bold18Style = const TextStyle(fontSize: 18, fontWeight: FontWeight.bold);

  const FilterDetail({
    super.key,
    required this.value,
    required this.devices,
    required this.tags,
    required this.sources,
    required this.onChanged,
    required this.onConfirm,
  });

  String get _startDateStr => value.startDate == '' ? TranslationKey.startDate.tr : value.startDate;

  String get _endDateStr => value.endDate == '' ? TranslationKey.endDate.tr : value.endDate;

  String get _nowDayStr => DateTime.now().toString().substring(0, 10);

  /// 按设备 id 取展示名，未命中时返回“未知”。
  String _getDevNameById(String devId) {
    for (final dev in devices) {
      if (dev.guid == devId) {
        return dev.displayName;
      }
    }
    return TranslationKey.unknown.tr;
  }

  Future<void> _onDateRangeClick(BuildContext context) async {
    //显示时间选择器
    var range = await showCalendarDatePicker2Dialog(
      context: context,
      config: CalendarDatePicker2WithActionButtonsConfig(calendarType: CalendarDatePicker2Type.range),
      dialogSize: const Size(325, 400),
      borderRadius: BorderRadius.circular(15),
    );
    if (range != null) {
      onChanged(
        value.copyWith(
          startDate: range[0]!.format('yyyy-MM-dd'),
          endDate: range[1]!.format('yyyy-MM-dd'),
        ),
      );
    }
  }

  /// 打开来源（应用）选择页；数据仍由外部通过回调提供。
  void _openAppSelection(BuildContext context) {
    final page = AppSelectionPage(
      loadDeviceName: _getDevNameById,
      selectedIds: value.appIds,
      loadAppInfos: () {
        final list = sources.map((item) => LocalAppInfo.fromAppInfo(item, false)).toList();
        return Future<List<LocalAppInfo>>.value(list);
      },
      onSelectedDone: (selected) {
        final appIds = Set.of(value.appIds);
        for (final item in selected) {
          appIds.add(item.appId);
        }
        onChanged(value.copyWith(appIds: appIds));
      },
    );
    if (context.isCompactScreen) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    } else {
      //todo 原使用 DynamicSizeWidget 约束来源选择弹窗尺寸，待新弹窗容器替代。
      dialogManager.open(context, page);
    }
  }

  void _toggleDev(String guid) {
    final devIds = Set.of(value.devIds);
    if (devIds.contains(guid)) {
      devIds.remove(guid);
    } else {
      devIds.add(guid);
    }
    onChanged(value.copyWith(devIds: devIds));
  }

  void _toggleTag(String tag) {
    final tags = Set.of(value.tags);
    if (tags.contains(tag)) {
      tags.remove(tag);
    } else {
      tags.add(tag);
    }
    onChanged(value.copyWith(tags: tags));
  }

  void _toggleApp(String appId) {
    final appIds = Set.of(value.appIds);
    if (appIds.contains(appId)) {
      appIds.remove(appId);
    } else {
      appIds.add(appId);
    }
    onChanged(value.copyWith(appIds: appIds));
  }

  @override
  Widget build(BuildContext context) {
    final confirmBtn = TextButton(
      onPressed: onConfirm,
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
                  icon: Icon(value.onlyNoSync ? Icons.check_box : Icons.check_box_outline_blank_sharp),
                  label: Text(TranslationKey.onlyNotSync.tr),
                  onPressed: () => onChanged(value.copyWith(onlyNoSync: !value.onlyNoSync)),
                ),
              ],
            ),
            Visibility(visible: context.isCompactScreen, child: confirmBtn),
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
            RoundedChip(
              onPressed: () => _onDateRangeClick(context),
              label: Text(_startDateStr, style: TextStyle(color: value.startDate == '' && _startDateStr == TranslationKey.startDate.tr ? Colors.blueGrey : null)),
              avatar: const Icon(Icons.date_range_outlined),
              deleteIcon: Icon(_startDateStr != _nowDayStr || _startDateStr == TranslationKey.startDate.tr ? Icons.location_on : Icons.close, size: 17, color: Colors.blue),
              deleteButtonTooltipMessage: _startDateStr != _nowDayStr || _startDateStr == TranslationKey.startDate.tr ? TranslationKey.toToday.tr : TranslationKey.clear.tr,
              onDeleted: _startDateStr != _nowDayStr
                  ? () => onChanged(value.copyWith(startDate: _nowDayStr))
                  : () => onChanged(value.copyWith(startDate: '')),
            ),
            Container(margin: const EdgeInsets.only(right: 10, left: 10), child: const Text('-')),
            RoundedChip(
              onPressed: () => _onDateRangeClick(context),
              label: Text(_endDateStr, style: TextStyle(color: value.endDate == '' && _endDateStr == TranslationKey.endDate.tr ? Colors.blueGrey : null)),
              avatar: const Icon(Icons.date_range_outlined),
              deleteIcon: Icon(_endDateStr != _nowDayStr || _endDateStr == TranslationKey.endDate.tr ? Icons.location_on : Icons.close, size: 17, color: Colors.blue),
              deleteButtonTooltipMessage: _endDateStr != _nowDayStr || _endDateStr == TranslationKey.endDate.tr ? TranslationKey.toToday.tr : TranslationKey.clear.tr,
              onDeleted: _endDateStr != _nowDayStr || _endDateStr == TranslationKey.endDate.tr
                  ? () => onChanged(value.copyWith(endDate: _nowDayStr))
                  : () => onChanged(value.copyWith(endDate: '')),
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
            Visibility(
              visible: value.devIds.isNotEmpty,
              child: SizedBox(
                height: 25,
                width: 25,
                child: IconButton(
                  padding: const EdgeInsets.all(2),
                  tooltip: TranslationKey.clear.tr,
                  iconSize: 13,
                  color: Colors.blueGrey,
                  onPressed: () => onChanged(value.copyWith(devIds: <String>{})),
                  icon: const Icon(Icons.cleaning_services_sharp),
                ),
              ),
            ),
          ],
        ),
        Visibility(visible: devices.isEmpty, child: emptyContent),
        const SizedBox(height: 5),
        Wrap(
          direction: Axis.horizontal,
          children: [
            for (var dev in devices)
              Container(
                margin: const EdgeInsets.only(right: 5, bottom: 5),
                child: RoundedChip(
                  onPressed: () => _toggleDev(dev.guid),
                  selected: value.devIds.contains(dev.guid),
                  label: Text(dev.displayName),
                ),
              ),
          ],
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
            Visibility(
              visible: value.tags.isNotEmpty,
              child: SizedBox(
                height: 25,
                width: 25,
                child: IconButton(
                  padding: const EdgeInsets.all(2),
                  tooltip: TranslationKey.clear.tr,
                  iconSize: 13,
                  color: Colors.blueGrey,
                  onPressed: () => onChanged(value.copyWith(tags: <String>{})),
                  icon: const Icon(Icons.cleaning_services_sharp),
                ),
              ),
            ),
          ],
        ),
        Visibility(visible: tags.isEmpty, child: emptyContent),
        const SizedBox(height: 5),
        Wrap(
          direction: Axis.horizontal,
          children: [
            for (var tag in tags)
              Container(
                margin: const EdgeInsets.only(right: 5, bottom: 5),
                child: RoundedChip(
                  onPressed: () => _toggleTag(tag),
                  selected: value.tags.contains(tag),
                  label: Text(tag),
                ),
              ),
          ],
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
                  Visibility(
                    visible: value.appIds.isNotEmpty,
                    child: SizedBox(
                      height: 25,
                      width: 25,
                      child: IconButton(
                        padding: const EdgeInsets.all(2),
                        tooltip: TranslationKey.clear.tr,
                        iconSize: 13,
                        color: Colors.blueGrey,
                        onPressed: () => onChanged(value.copyWith(appIds: <String>{})),
                        icon: const Icon(Icons.cleaning_services_sharp),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            RoundedChip(
              avatar: const Icon(Icons.add),
              label: Text(TranslationKey.selection.tr),
              onPressed: () => _openAppSelection(context),
            ),
          ],
        ),
        AppInfoGroupsView(
          appInfos: sources.where((app) => value.appIds.contains(app.appId)).toList(),
          loadDevName: _getDevNameById,
          onPress: (app) => _toggleApp(app.appId),
        ),
        //endregion
      ],
    );
    const padding = EdgeInsets.all(8);
    //这里不能使用visibility，否则会导致 RoundedChip 的背景色失效
    return SafeArea(
      child: ConditionWidget(
        visible: !context.isCompactScreen,
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
      ),
    );
  }
}

/// [FilterDetail] 的面板包装：在弹窗/抽屉内维护本地草稿值，
/// 条件变化只更新本地，确认时再一次性上报并触发搜索。
class FilterDetailSheet extends StatefulWidget {
  final SearchFilter value;
  final List<Device> devices;
  final List<String> tags;
  final List<AppInfo> sources;
  final ValueChanged<SearchFilter> onChanged;
  final VoidCallback onConfirm;

  /// 确认后关闭面板的回调；为 null 时由外部（如抽屉）自行处理关闭。
  final VoidCallback? onClose;

  const FilterDetailSheet({
    super.key,
    required this.value,
    required this.devices,
    required this.tags,
    required this.sources,
    required this.onChanged,
    required this.onConfirm,
    this.onClose,
  });

  @override
  State<FilterDetailSheet> createState() => _FilterDetailSheetState();
}

class _FilterDetailSheetState extends State<FilterDetailSheet> {
  late SearchFilter _value;

  @override
  void initState() {
    super.initState();
    _value = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return FilterDetail(
      value: _value,
      devices: widget.devices,
      tags: widget.tags,
      sources: widget.sources,
      onChanged: (filter) => setState(() => _value = filter),
      onConfirm: () {
        widget.onChanged(_value);
        widget.onConfirm();
        widget.onClose?.call();
      },
    );
  }
}
