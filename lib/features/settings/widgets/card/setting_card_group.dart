import 'package:clipshare/features/settings/widgets/card/setting_entry.dart';
import 'package:flutter/cupertino.dart';

import 'setting_header.dart';

class SettingCardGroup extends StatelessWidget {
  final String? groupName;
  final Icon? icon;
  final List<SettingEntry> cardList;
  final double radius;
  final Widget Function(BuildContext context)? headerBuilder;
  final bool showHeader;

  const SettingCardGroup({
    super.key,
    this.groupName,
    this.icon,
    required this.cardList,
    this.radius = 8.0,
    this.headerBuilder,
    this.showHeader = true,
  });

  @override
  Widget build(BuildContext context) {
    assert(() {
      if (showHeader && headerBuilder == null) {
        return groupName != null && icon != null;
      }
      return true;
    }());
    var topBorder = BorderRadius.only(
      topLeft: Radius.circular(radius),
      topRight: Radius.circular(radius),
    );
    var bottomBorder = BorderRadius.only(
      bottomLeft: Radius.circular(radius),
      bottomRight: Radius.circular(radius),
    );
    var allBorder = BorderRadius.all(Radius.circular(radius));
    var showList = cardList.where((card) => card.visible).toList();
    return showList.isEmpty
        ? const SizedBox.shrink()
        : Column(
            children: [
              if (showHeader)
                headerBuilder == null ? SettingHeader(title: groupName!, icon: icon!) : headerBuilder!.call(context),
              for (var i = 0; i < showList.length; i++)
                showList[i].buildWithLayout(
                  borderRadius: showList.length == 1
                      ? allBorder
                      : (i == 0
                            ? topBorder
                            : i == showList.length - 1
                            ? bottomBorder
                            : BorderRadius.zero),
                  separate: showList.length != 1 && i != showList.length - 1,
                ),
            ],
          );
  }
}
