import 'package:clipshare/app/data/models/chart/pie_data_item.dart';
import 'package:clipshare/app/widgets/statistics/indicators.dart';
import 'package:flutter/cupertino.dart';
import 'package:graphic/graphic.dart';

class PieChart extends StatelessWidget {
  final List<PieDataItem> data;
  final String title;
  final AlignmentGeometry? titleAlign;

  const PieChart({
    super.key,
    required this.data,
    required this.title,
    this.titleAlign,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> names = [];
    for (var item in data) {
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
            child: Indicators(
              names: names,
              title: title,
              titleAlign: titleAlign,
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
                )
              ],
              marks: [
                IntervalMark(
                  position: Varset('percent') / Varset('name'),
                  label: LabelEncode(
                      encoder: (tuple) => Label(
                            tuple['value'].toString(),
                            LabelStyle(textStyle: Defaults.runeStyle),
                          )),
                  color:
                      ColorEncode(variable: 'name', values: Defaults.colors10),
                  modifiers: [StackModifier()],
                )
              ],
              coord: PolarCoord(transposed: true, dimCount: 1),
            ),
          ),
        ],
      ),
    );
  }
}
