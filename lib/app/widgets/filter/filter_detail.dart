import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/models/search_filter.dart';
import 'package:clipshare/app/data/repository/entity/tables/device.dart';
import 'package:clipshare/app/utils/extensions/time_extension.dart';
import 'package:clipshare/app/widgets/condition_widget.dart';
import 'package:clipshare/app/widgets/empty_content.dart';
import 'package:clipshare/app/widgets/rounded_chip.dart';
import 'package:flutter/material.dart';

class FilterDetail extends StatefulWidget {
  final SearchFilter filter;
  final List<Device> allDevices;
  final List<String> allTagNames;
  final bool isBigScreen;
  final void Function(SearchFilter filter) onConfirm;

  FilterDetail({
    super.key,
    required SearchFilter searchFilter,
    required this.allDevices,
    required this.allTagNames,
    required this.onConfirm,
    required this.isBigScreen,
  }) : filter = searchFilter.copy();

  @override
  State<StatefulWidget> createState() => _FilterDetailState();
}

class _FilterDetailState extends State<FilterDetail> {
  SearchFilter get filter => widget.filter;
  final bold18Style = const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  void onDateRangeClick() async {
    //显示时间选择器
    var range = await showCalendarDatePicker2Dialog(
      context: context,
      config: CalendarDatePicker2WithActionButtonsConfig(
        calendarType: CalendarDatePicker2Type.range,
      ),
      dialogSize: const Size(325, 400),
      borderRadius: BorderRadius.circular(15),
    );
    if (range != null) {
      widget.filter.startDate = range[0]!.format("yyyy-MM-dd");
      widget.filter.endDate = range[1]!.format("yyyy-MM-dd");
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    var start = filter.startDate == "" ? TranslationKey.startDate.tr : filter.startDate;
    var end = filter.endDate == "" ? TranslationKey.endDate.tr : filter.endDate;
    var now = DateTime.now();
    var nowDayStr = now.toString().substring(0, 10);

    final confirmBtn = TextButton(
      onPressed: () {
        widget.onConfirm(filter.copy());
      },
      child: Text(TranslationKey.confirm.tr),
    );
    final header = Row(
      children: [
        Expanded(
          child: Row(
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
                style: bold18Style.copyWith(color: Colors.blueGrey),
              )
            ],
          ),
        ),
        Row(
          children: [
            Row(
              children: [
                TextButton.icon(
                  icon: Icon(
                    filter.onlyNoSync ? Icons.check_box : Icons.check_box_outline_blank_sharp,
                  ),
                  label: Text(
                    TranslationKey.onlyNotSync.tr,
                  ),
                  onPressed: () {
                    setState(() {
                      filter.onlyNoSync = !filter.onlyNoSync;
                    });
                  },
                ),
              ],
            ),
            Visibility(
              visible: !widget.isBigScreen,
              child: confirmBtn,
            ),
          ],
        ),
      ],
    );
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        //筛选日期 label
        Container(
          margin: const EdgeInsets.only(bottom: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                TranslationKey.filterByDate.tr,
                style: bold18Style,
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            RoundedChip(
              onPressed: onDateRangeClick,
              label: Text(
                start,
                style: TextStyle(
                  color: filter.startDate == "" && start == TranslationKey.startDate.tr ? Colors.blueGrey : null,
                ),
              ),
              avatar: const Icon(Icons.date_range_outlined),
              deleteIcon: Icon(
                start != nowDayStr || start == TranslationKey.startDate.tr ? Icons.location_on : Icons.close,
                size: 17,
                color: Colors.blue,
              ),
              deleteButtonTooltipMessage: start != nowDayStr || start == TranslationKey.startDate.tr ? TranslationKey.toToday.tr : TranslationKey.clear.tr,
              onDeleted: start != nowDayStr
                  ? () {
                      filter.startDate = DateTime.now().toString().substring(0, 10);
                      setState(() {});
                    }
                  : () {
                      filter.startDate = "";
                      setState(() {});
                    },
            ),
            Container(
              margin: const EdgeInsets.only(right: 10, left: 10),
              child: const Text("-"),
            ),
            RoundedChip(
              onPressed: onDateRangeClick,
              label: Text(
                end,
                style: TextStyle(
                  color: filter.endDate == "" && end == TranslationKey.endDate.tr ? Colors.blueGrey : null,
                ),
              ),
              avatar: const Icon(Icons.date_range_outlined),
              deleteIcon: Icon(
                end != nowDayStr || end == TranslationKey.endDate.tr ? Icons.location_on : Icons.close,
                size: 17,
                color: Colors.blue,
              ),
              deleteButtonTooltipMessage: end != nowDayStr || end == TranslationKey.endDate.tr ? TranslationKey.toToday.tr : TranslationKey.clear.tr,
              onDeleted: end != nowDayStr || end == TranslationKey.endDate.tr
                  ? () {
                      filter.endDate = DateTime.now().toString().substring(0, 10);
                      setState(() {});
                    }
                  : () {
                      filter.endDate = "";
                      setState(() {});
                    },
            ),
          ],
        ),
        //筛选设备
        Row(
          children: <Widget>[
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 10),
              child: Text(
                TranslationKey.filterByDevice.tr,
                style: bold18Style,
              ),
            ),
            const SizedBox(
              width: 5,
            ),
            filter.devIds.isNotEmpty
                ? SizedBox(
                    height: 25,
                    width: 25,
                    child: IconButton(
                      padding: const EdgeInsets.all(2),
                      tooltip: TranslationKey.clear.tr,
                      iconSize: 13,
                      color: Colors.blueGrey,
                      onPressed: () {
                        filter.devIds.clear();
                        setState(() {});
                      },
                      icon: const Icon(
                        Icons.cleaning_services_sharp,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ],
        ),
        if (widget.allDevices.isEmpty) EmptyContent(size: 40),
        const SizedBox(height: 5),
        Wrap(
          direction: Axis.horizontal,
          children: [
            for (var dev in widget.allDevices)
              Container(
                margin: const EdgeInsets.only(right: 5, bottom: 5),
                child: RoundedChip(
                  onPressed: () {
                    var guid = dev.guid;
                    if (filter.devIds.contains(guid)) {
                      filter.devIds.remove(guid);
                    } else {
                      filter.devIds.add(guid);
                    }
                    setState(() {});
                  },
                  selected: filter.devIds.contains(dev.guid),
                  label: Text(dev.name),
                ),
              ),
          ],
        ),
        //筛选标签
        Row(
          children: <Widget>[
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 10),
              child: Text(
                TranslationKey.filterByTag.tr,
                style: bold18Style,
              ),
            ),
            const SizedBox(width: 5),
            filter.tags.isNotEmpty
                ? SizedBox(
                    height: 25,
                    width: 25,
                    child: IconButton(
                      padding: const EdgeInsets.all(2),
                      tooltip: TranslationKey.clear.tr,
                      iconSize: 13,
                      color: Colors.blueGrey,
                      onPressed: () {
                        filter.tags.clear();
                        setState(() {});
                      },
                      icon: const Icon(
                        Icons.cleaning_services_sharp,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ],
        ),
        if (widget.allTagNames.isEmpty) EmptyContent(size: 40),
        const SizedBox(height: 5),
        Wrap(
          direction: Axis.horizontal,
          children: [
            for (var tag in widget.allTagNames)
              Container(
                margin: const EdgeInsets.only(right: 5, bottom: 5),
                child: RoundedChip(
                  onPressed: () {
                    if (filter.tags.contains(tag)) {
                      filter.tags.remove(tag);
                    } else {
                      filter.tags.add(tag);
                    }
                    setState(() {});
                  },
                  selected: filter.tags.contains(tag),
                  label: Text(tag),
                ),
              ),
          ],
        ),
      ],
    );
    const padding = EdgeInsets.all(8);
    //这里不能使用visibility，否则会导致 RoundedChip 的背景色失效
    return ConditionWidget(
      visible: widget.isBigScreen,
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
