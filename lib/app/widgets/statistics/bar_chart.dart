import 'dart:math';
import 'dart:ui';

import 'package:clipshare/app/data/models/chart/bar_chart_item.dart';
import 'package:clipshare/app/widgets/statistics/indicators.dart';
import 'package:flutter/material.dart';
import 'package:graphic/graphic.dart';

class BarChart extends StatelessWidget {
  final List<BarChartItem> data;
  final String title;
  final AlignmentGeometry? titleAlign;

  const BarChart({
    super.key,
    required this.data,
    required this.title,
    this.titleAlign,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> indexNames = [];
    final groups = <String, List<BarChartItem>>{};
    for (var item in data) {
      if (groups.containsKey(item.index)) {
        groups[item.index]!.add(item);
      } else {
        groups[item.index] = [item];
      }
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
            child: Indicators(
              names: indexNames,
              title: title,
              titleAlign: titleAlign,
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
              'tooltipMouse': PointSelection(on: {
                GestureType.hover,
              }, devices: {
                PointerDeviceKind.mouse
              }, variable: 'index'),
              'groupMouse': PointSelection(
                  on: {
                    GestureType.hover,
                  },
                  variable: 'index',
                  devices: {PointerDeviceKind.mouse}),
              'tooltipTouch': PointSelection(on: {
                GestureType.scaleUpdate,
                GestureType.tapDown,
                GestureType.longPressMoveUpdate
              }, devices: {
                PointerDeviceKind.touch
              }, variable: 'index'),
              'groupTouch': PointSelection(
                  on: {
                    GestureType.scaleUpdate,
                    GestureType.tapDown,
                    GestureType.longPressMoveUpdate
                  },
                  variable: 'index',
                  devices: {PointerDeviceKind.touch}),
            },
            tooltip: TooltipGuide(
              selections: {'tooltipTouch', 'tooltipMouse'},
              followPointer: [true, true],
              renderer: (size, anchor, selected) {
                return simpleTooltip(
                  "index",
                  'name',
                  "value",
                  anchor,
                  selected,
                );
              },
            ),
            crosshair: CrosshairGuide(
              selections: {'tooltipTouch', 'tooltipMouse'},
              followPointer: [false, true],
            ),
          )),
        ],
      ),
    );
  }
}

List<MarkElement> simpleTooltip(
  String? titleKey,
  String labelKey,
  String valueKey,
  Offset anchor,
  Map<int, Tuple> selectedTuples,
) {
  List<MarkElement> elements = List.empty(growable: true);
  const textStyle = TextStyle(fontSize: 12, color: Colors.black);
  const elevation = 4.0;
  const backgroundColor = Colors.white;
  final selectedTupleList = selectedTuples.values;
  double maxWidth = 0.0;
  double maxHeight = 0.0;
  List<MarkElement> temp = [];
  String? title = null;
  var i = 0;
  for (var data in selectedTupleList) {
    if (titleKey != null && title == null) {
      title = data[titleKey].toString();
      //获取文本画笔
      final painter = TextPainter(
        text: TextSpan(text: title, style: textStyle),
        textDirection: TextDirection.ltr,
      );
      //绘制
      painter.layout();

      //计算起始点和绘制区域
      var paintPoint = anchor + const Offset(-4, -2.5);
      //更新历史最大值
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
    dynamic label = data[labelKey];
    dynamic value = data[valueKey];
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
    //获取文本画笔
    final painter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
    );
    //绘制
    painter.layout();

    var paintPoint = anchor + Offset(radius * 2, maxHeight + radius * 1.5);
    //更新历史最大值
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
  double padding = 10;
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
