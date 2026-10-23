import 'dart:math';
import 'dart:ui';

import 'package:clipshare/core/database/app_database.dart';
import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/services/device/local_device_info.dart';
import 'package:clipshare/core/services/device/local_device_info_provider.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/enums/history_content_type.dart';
import 'package:clipshare/shared/extensions/context_extension.dart';
import 'package:clipshare/shared/extensions/time_extension.dart';
import 'package:clipshare/shared/models/chart/bar_chart_item.dart';
import 'package:clipshare/shared/models/chart/pie_data_item.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:clipshare/shared/widgets/base/empty_content.dart';
import 'package:clipshare/shared/widgets/base/rounded_chip.dart';
import 'package:clipshare/shared/widgets/dot.dart';
import 'package:clipshare/shared/widgets/loading/loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphic/graphic.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';

const _tag = 'SettingsStatisticsPage';

/// 统计页，展示历史记录的类型、标签、设备分布与同步比例。
class SettingsStatisticsPage extends ConsumerStatefulWidget {
  final bool embedded;

  const SettingsStatisticsPage({
    super.key,
    this.embedded = false,
  });

  @override
  ConsumerState<SettingsStatisticsPage> createState() => _SettingsStatisticsPageState();
}

class _SettingsStatisticsPageState extends ConsumerState<SettingsStatisticsPage> {

  /// 月份筛选与数据库聚合使用的统一格式。
  static const _monthFormat = 'yyyy-MM';

  late String _startMonth;
  late String _endMonth;

  final List<BarChartItem> _historyTypeCntItems = [];
  final List<BarChartItem> _historyTagCntItems = [];
  final List<PieDataItem> _syncRatePieItems = [];
  final List<BarChartItem> _historyCntForDeviceItems = [];

  /// 首次加载是否已完成，用于区分加载态与空状态。
  bool _loaded = false;

  /// 是否正在刷新，用于刷新按钮的进度反馈。
  bool _refreshing = false;

  /// 递增标记，丢弃过期刷新结果，避免月份切换后旧数据覆盖新数据。
  int _refreshToken = 0;

  /// 数据库实例。
  Future<AppDatabase> get _db => ref.read(appDbProvider.future);

  /// 本机设备信息，用于识别设备维度的自身统计。
  Future<LocalDeviceInfo> get _localDevice => ref.read(localDeviceInfoProvider.future);

  bool get _isAllEmpty =>
      _historyTypeCntItems.isEmpty &&
      _historyTagCntItems.isEmpty &&
      _syncRatePieItems.isEmpty &&
      _historyCntForDeviceItems.isEmpty;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final month = DateTime(now.year, now.month).format(_monthFormat);
    _startMonth = month;
    _endMonth = month;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  /// 重新加载全部统计数据。
  ///
  /// 统一在加载完成后一次性更新状态，避免多个统计维度分步刷新造成闪烁。
  Future<void> _refreshData() async {
    final token = ++_refreshToken;
    if (!mounted) {
      return;
    }
    setState(() => _refreshing = true);
    try {
      final db = await _db;
      final localDevice = await _localDevice;
      final typeItems = await _loadHistoryTypeCnt(db);
      final tagItems = await _loadHistoryTagCnt(db);
      final deviceStats = await _loadHistoryCntForDevice(db, localDevice);
      if (!mounted || token != _refreshToken) {
        return;
      }
      setState(() {
        _historyTypeCntItems
          ..clear()
          ..addAll(typeItems);
        _historyTagCntItems
          ..clear()
          ..addAll(tagItems);
        _historyCntForDeviceItems
          ..clear()
          ..addAll(deviceStats.items);
        _syncRatePieItems
          ..clear()
          ..addAll(deviceStats.pieItems);
        _loaded = true;
        _refreshing = false;
      });
    } catch (err, stack) {
      logger.error(_tag, err, stack);
      if (!mounted || token != _refreshToken) {
        return;
      }
      setState(() {
        _loaded = true;
        _refreshing = false;
      });
    }
  }

  /// 选择统计的月份范围。
  Future<void> _selectRangeMonth() async {
    final res = await showMonthRangePicker(context: context);
    if (res == null || !mounted) {
      return;
    }
    setState(() {
      _startMonth = res[0].format(_monthFormat);
      _endMonth = res[1].format(_monthFormat);
    });
  }

  /// 不同类型的历史记录数量。
  Future<List<BarChartItem>> _loadHistoryTypeCnt(AppDatabase db) async {
    final typeCntList = await db.historyDao.getHistoryTypeCnt(
      _startMonth,
      _endMonth,
    );
    final items = typeCntList
        .map((e) => BarChartItem(name: e.type, index: e.date, value: e.cnt))
        .toList();
    _padBarItems(items, _contentTypeNameCompare);
    return items;
  }

  /// 各个标签的历史记录引用数量。
  Future<List<BarChartItem>> _loadHistoryTagCnt(AppDatabase db) async {
    final res = await db.historyTagDao.getHistoryTagCnt(
      _startMonth,
      _endMonth,
    );
    return res
        .map((e) => BarChartItem(name: e.tagName, index: e.tagName, value: e.cnt))
        .toList();
  }

  /// 各设备的历史记录数量，并计算本机与同步记录占比。
  Future<({List<BarChartItem> items, List<PieDataItem> pieItems})> _loadHistoryCntForDevice(
    AppDatabase db,
    LocalDeviceInfo localDevice,
  ) async {
    final res = await db.historyDao.getHistoryCntForDevice(
      _startMonth,
      _endMonth,
      localDevice,
    );
    final items = res
        .map((e) => BarChartItem(name: e.devName, index: e.month, value: e.cnt))
        .toList();
    _padBarItems(items);

    final selfId = localDevice.baseDeviceInfo.guid;
    var sync = 0;
    var self = 0;
    for (final item in res) {
      if (item.devId == selfId) {
        self += item.cnt;
      } else {
        sync += item.cnt;
      }
    }
    final pieItems = res.isEmpty
        ? <PieDataItem>[]
        : [
            PieDataItem(TranslationKey.pieDataStatisticsLocalItemLabel.tr, self),
            PieDataItem(TranslationKey.pieDataStatisticsSyncItemLabel.tr, sync),
          ];
    return (items: items, pieItems: pieItems);
  }

  /// 补齐各月份缺失的类别，使柱状图分组数据完整。
  ///
  /// [nameCompare] 用于同一月份内多个类别的排序，未提供时按名称排序。
  void _padBarItems(
    List<BarChartItem> items, [
    int Function(String a, String b)? nameCompare,
  ]) {
    final groupIndexes = <String, Set<String>>{};
    final allNames = <String>{};
    for (final item in items) {
      allNames.add(item.name);
      groupIndexes.putIfAbsent(item.index, () => <String>{}).add(item.name);
    }
    for (final month in groupIndexes.keys) {
      final diff = allNames.difference(groupIndexes[month]!);
      for (final name in diff) {
        items.add(BarChartItem(name: name, index: month, value: 0));
      }
    }
    items.sort((a, b) {
      final compareIndex = a.index.compareTo(b.index);
      if (compareIndex != 0) {
        return compareIndex;
      }
      if (nameCompare != null) {
        return nameCompare(a.name, b.name);
      }
      return a.name.compareTo(b.name);
    });
  }

  /// 按内容类型的展示顺序比较名称。
  int _contentTypeNameCompare(String a, String b) {
    return HistoryContentType.parse(a).order.compareTo(HistoryContentType.parse(b).order);
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent(context);
    if (context.isCompactScreen) {
      return Scaffold(
        appBar: AppBar(
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.bar_chart),
              const SizedBox(width: 10),
              Text(TranslationKey.statisticsPageAppBarText.tr),
            ],
          ),
        ),
        body: SafeArea(child: content),
      );
    }
    return Card(
      color: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      margin: const EdgeInsets.all(8),
      child: content,
    );
  }

  Widget _buildContent(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              Text(TranslationKey.statisticsPageFilterRangeText.tr),
              const SizedBox(width: 10),
              RoundedChip(
                onPressed: _selectRangeMonth,
                label: Text(_startMonth),
                avatar: const Icon(Icons.date_range_outlined),
              ),
              Container(
                margin: const EdgeInsets.only(right: 10, left: 10),
                child: const Text('-'),
              ),
              RoundedChip(
                onPressed: _selectRangeMonth,
                label: Text(_endMonth),
                avatar: const Icon(Icons.date_range_outlined),
              ),
              if (_refreshing)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Loading(width: 20),
                )
              else
                Tooltip(
                  message: TranslationKey.refresh.tr,
                  child: IconButton(
                    onPressed: _refreshData,
                    icon: const Icon(Icons.refresh),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: !_loaded
                ? const Center(child: Loading())
                : Row(
                    children: [
                      Expanded(child: Container()),
                      Container(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: _isAllEmpty
                            ? const EmptyContent()
                            : GridView.count(
                                crossAxisCount: 1,
                                children: [
                                  if (_historyTypeCntItems.isNotEmpty)
                                    _BarChart(
                                      data: _historyTypeCntItems,
                                      title: TranslationKey.statisticsPageHistoryTypeCntTitle.tr,
                                    ),
                                  if (_syncRatePieItems.isNotEmpty)
                                    _PieChart(
                                      data: _syncRatePieItems,
                                      title: TranslationKey.statisticsPageSyncRatePie.tr,
                                    ),
                                  if (_historyCntForDeviceItems.isNotEmpty)
                                    _BarChart(
                                      data: _historyCntForDeviceItems,
                                      title: TranslationKey.statisticsPageHistoryCntForDevice.tr,
                                    ),
                                  if (_historyTagCntItems.isNotEmpty)
                                    _BarChart(
                                      data: _historyTagCntItems,
                                      title: TranslationKey.statisticsPageHistoryTagCnt.tr,
                                    ),
                                ],
                              ),
                      ),
                      Expanded(child: Container()),
                    ],
                  ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

/// 图表标题与图例。
class _Indicators extends StatelessWidget {
  final List<String> names;
  final String title;

  const _Indicators({
    required this.names,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.only(left: 10, right: 10),
          child: Align(
            alignment: Alignment.center,
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              names.length,
              (index) {
                return Container(
                  margin: names.length != 1 && names.length - 1 != index
                      ? const EdgeInsets.only(right: 10)
                      : null,
                  child: _Indicator(
                    name: names[index],
                    color: Defaults.colors10[index % Defaults.colors10.length],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// 图例中的单项标识：颜色圆点与名称。
class _Indicator extends StatelessWidget {
  final String name;
  final Color color;

  const _Indicator({
    required this.name,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Dot(radius: 5, color: color),
        const SizedBox(width: 5),
        Text(name),
      ],
    );
  }
}

/// 分组的堆叠柱状图，展示按月聚合的统计数据。
class _BarChart extends StatelessWidget {
  final List<BarChartItem> data;
  final String title;

  const _BarChart({
    required this.data,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> indexNames = [];
    for (final item in data) {
      if (indexNames.contains(item.name)) {
        continue;
      }
      indexNames.add(item.name);
    }
    return Container(
      margin: const EdgeInsets.only(top: 10),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 5),
            child: _Indicators(
              names: indexNames,
              title: title,
            ),
          ),
          Expanded(
            child: Chart(
              data: data,
              variables: {
                'index': Variable(
                  accessor: (BarChartItem item) => item.index,
                ),
                'name': Variable(
                  accessor: (BarChartItem item) => item.name,
                ),
                'value': Variable(
                  accessor: (BarChartItem item) => item.value,
                ),
              },
              marks: [
                IntervalMark(
                  position: Varset('index') * Varset('value') / Varset('name'),
                  shape: ShapeEncode(value: RectShape(labelPosition: 0.5)),
                  color: ColorEncode(variable: 'name', values: Defaults.colors10),
                  label: LabelEncode(
                    encoder: (tuple) => Label(
                      tuple['value'].toString(),
                      LabelStyle(
                        textStyle: const TextStyle(fontSize: 6),
                      ),
                    ),
                  ),
                  modifiers: [StackModifier()],
                ),
              ],
              coord: RectCoord(
                horizontalRangeUpdater: Defaults.horizontalRangeEvent,
              ),
              axes: [
                Defaults.horizontalAxis,
                Defaults.verticalAxis,
              ],
              selections: {
                'tooltipMouse': PointSelection(
                  on: {
                    GestureType.hover,
                  },
                  devices: {
                    PointerDeviceKind.mouse,
                  },
                  variable: 'index',
                ),
                'groupMouse': PointSelection(
                  on: {
                    GestureType.hover,
                  },
                  variable: 'index',
                  devices: {PointerDeviceKind.mouse},
                ),
                'tooltipTouch': PointSelection(
                  on: {
                    GestureType.scaleUpdate,
                    GestureType.tapDown,
                    GestureType.longPressMoveUpdate,
                  },
                  devices: {
                    PointerDeviceKind.touch,
                  },
                  variable: 'index',
                ),
                'groupTouch': PointSelection(
                  on: {
                    GestureType.scaleUpdate,
                    GestureType.tapDown,
                    GestureType.longPressMoveUpdate,
                  },
                  variable: 'index',
                  devices: {PointerDeviceKind.touch},
                ),
              },
              tooltip: TooltipGuide(
                selections: {'tooltipTouch', 'tooltipMouse'},
                followPointer: [true, true],
                renderer: (size, anchor, selected) {
                  return _simpleTooltip(
                    'index',
                    'name',
                    'value',
                    anchor,
                    selected,
                  );
                },
              ),
              crosshair: CrosshairGuide(
                selections: {'tooltipTouch', 'tooltipMouse'},
                followPointer: [false, true],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 饼图，展示本机与同步记录的比例。
class _PieChart extends StatelessWidget {
  final List<PieDataItem> data;
  final String title;

  const _PieChart({
    required this.data,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> names = [];
    for (final item in data) {
      if (names.contains(item.name)) {
        continue;
      }
      names.add(item.name);
    }
    return Container(
      margin: const EdgeInsets.only(top: 10),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 5),
            child: _Indicators(
              names: names,
              title: title,
            ),
          ),
          Expanded(
            child: Chart(
              data: data,
              variables: {
                'name': Variable(
                  accessor: (PieDataItem item) => item.name,
                ),
                'value': Variable(
                  accessor: (PieDataItem item) => item.value,
                ),
              },
              transforms: [
                Proportion(
                  variable: 'value',
                  as: 'percent',
                ),
              ],
              marks: [
                IntervalMark(
                  position: Varset('percent') / Varset('name'),
                  label: LabelEncode(
                    encoder: (tuple) => Label(
                      tuple['value'].toString(),
                      LabelStyle(textStyle: Defaults.runeStyle),
                    ),
                  ),
                  color: ColorEncode(variable: 'name', values: Defaults.colors10),
                  modifiers: [StackModifier()],
                ),
              ],
              coord: PolarCoord(transposed: true, dimCount: 1),
            ),
          ),
        ],
      ),
    );
  }
}

/// 柱状图悬浮提示渲染，列出当前分组内的名称与数值。
List<MarkElement> _simpleTooltip(
  String? titleKey,
  String labelKey,
  String valueKey,
  Offset anchor,
  Map<int, Tuple> selectedTuples,
) {
  final elements = <MarkElement>[];
  const textStyle = TextStyle(fontSize: 12, color: Colors.black);
  const elevation = 4.0;
  const backgroundColor = Colors.white;
  final selectedTupleList = selectedTuples.values;
  double maxWidth = 0.0;
  double maxHeight = 0.0;
  final temp = <MarkElement>[];
  String? title;
  var i = 0;
  for (final data in selectedTupleList) {
    if (titleKey != null && title == null) {
      title = data[titleKey].toString();
      final painter = TextPainter(
        text: TextSpan(text: title, style: textStyle),
        textDirection: TextDirection.ltr,
      );
      painter.layout();

      final paintPoint = anchor + const Offset(-4, -2.5);
      maxWidth = max(maxWidth, painter.width);
      maxHeight += painter.height;
      temp.add(
        LabelElement(
          text: title,
          anchor: paintPoint,
          style: LabelStyle(textStyle: textStyle, align: Alignment.centerRight),
        ),
      );
    }
    final dynamic label = data[labelKey];
    final dynamic value = data[valueKey];
    const radius = 5.0;
    temp.add(
      CircleElement(
        center: anchor + Offset(0, maxHeight),
        radius: radius,
        style: PaintStyle(
          fillColor: Defaults.colors10[i % 10],
        ),
      ),
    );
    i++;
    final text = '$label: $value';
    final painter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
    );
    painter.layout();

    final paintPoint = anchor + Offset(radius * 2, maxHeight + radius * 1.5);
    maxWidth = max(maxWidth, painter.width + radius * 3);
    maxHeight += painter.height;
    temp.add(
      LabelElement(
        text: text,
        anchor: paintPoint,
        style: LabelStyle(
          textStyle: textStyle,
          align: Alignment.topRight,
        ),
      ),
    );
  }
  const padding = 10.0;
  final window = Rect.fromLTWH(
    anchor.dx - padding * 1.5,
    anchor.dy - padding * 1.5,
    maxWidth + padding * 2,
    maxHeight + padding * 2,
  );

  elements.add(
    RectElement(
      borderRadius: BorderRadius.circular(4),
      rect: window,
      style: PaintStyle(fillColor: backgroundColor, elevation: elevation),
    ),
  );
  elements.addAll(temp);
  return elements;
}
