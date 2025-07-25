import 'package:clipshare/app/data/repository/entity/tables/app_info.dart';
import 'package:clipshare/app/utils/extensions/list_extension.dart';
import 'package:clipshare/app/widgets/filter/filter_detail.dart';
import 'package:clipshare/app/widgets/rounded_chip.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppInfoGroupsView extends StatelessWidget {
  final List<AppInfo> appInfos;
  final void Function(AppInfo app)? onPress;
  final String Function(String) loadDevName;

  const AppInfoGroupsView({
    super.key,
    required this.appInfos,
    required this.onPress,
    required this.loadDevName,
  });

  @override
  Widget build(BuildContext context) {
    final groups = appInfos.groupBy((item) => item.devId);
    if (appInfos.isEmpty) {
      return FilterDetail.emptyContent;
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
                    Text(loadDevName(devId)),
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
                      onPressed: () => onPress?.call(app),
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
  }
}
