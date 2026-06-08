import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/repository/entity/tables/device.dart';
import 'package:clipshare/app/widgets/device/device_card_simple.dart';
import 'package:clipshare/app/widgets/empty_content.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:get/get.dart';

class OnlineDevices extends StatelessWidget {
  final Axis direction;
  final List<Device> onlineList;
  final List<Device> selectedList;
  final void Function(Device device) onTap;

  const OnlineDevices({
    super.key,
    this.direction = Axis.vertical,
    required this.onlineList,
    required this.onTap,
    required this.selectedList,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: onlineList.isEmpty ? MainAxisAlignment.center : MainAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(left: 10, bottom: 5),
          child: Row(
            children: [
              const Icon(
                Icons.devices_outlined,
              ),
              const SizedBox(width: 5),
              Text(
                TranslationKey.onlineDevices.tr,
                style: const TextStyle(fontSize: 17),
              ),
            ],
          ),
        ),
        Expanded(
          child: Visibility(
            visible: onlineList.isNotEmpty,
            replacement: Center(
              child: EmptyContent(
                description: TranslationKey.noOnlineDevices.tr,
              ),
            ),
            child: ListView.builder(
              scrollDirection: direction,
              itemCount: onlineList.length,
              physics: const AlwaysScrollableScrollPhysics(),
              itemBuilder: (ctx, idx) {
                var dev = onlineList[idx];
                return DeviceCardSimple(
                  dev: dev,
                  width: direction == Axis.horizontal ? 200 : null,
                  showBorder: selectedList.contains(dev),
                  onTap: () {
                    onTap(dev);
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
