import 'package:clipshare/app/data/models/chart/pie_data_item.dart';
import 'package:flutter/cupertino.dart';
import 'package:graphic/graphic.dart';

class SyncRosePie extends StatelessWidget {
  final List<PieDataItem> data;

  const SyncRosePie({super.key,required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      width: 350,
      height: 300,
      child: Chart(
        data: data,
        variables: {
          'name': Variable(
            accessor: (PieDataItem item) => item.name,
          ),
          'value': Variable(
            accessor: (PieDataItem item) => item.value,
            scale: LinearScale(min: 0, marginMax: 0.1),
          ),
        },
        marks: [
          IntervalMark(
            label: LabelEncode(
                encoder: (tuple) => Label(tuple['name'].toString())),
            shape: ShapeEncode(
                value: RectShape(
              borderRadius: const BorderRadius.all(Radius.circular(10)),
            )),
            color: ColorEncode(variable: 'name', values: Defaults.colors10),
            elevation: ElevationEncode(value: 5),
          )
        ],
        coord: PolarCoord(startRadius: 0.15),
      ),
    );
  }
}
