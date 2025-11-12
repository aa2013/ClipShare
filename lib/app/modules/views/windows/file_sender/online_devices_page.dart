import 'dart:io';
import 'dart:math';

import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/repository/entity/tables/device.dart';
import 'package:clipshare/app/services/pending_file_service.dart';
import 'package:clipshare/app/utils/extensions/platform_extension.dart';
import 'package:clipshare/app/utils/file_util.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/widgets/dragAndSendFiles/online_devices.dart';
import 'package:clipshare/app/widgets/dragAndSendFiles/pending_file_list.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FileSenderPage extends StatelessWidget {
  final List<Device> devices;
  final pendingFileService = Get.find<PendingFileService>();
  final void Function(DropItem item) onItemRemove;
  final Function(List<Device> devives, List<DropItem> items) onSendClicked;

  FileSenderPage({
    super.key,
    required this.devices,
    required this.onSendClicked,
    required this.onItemRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PlatformExt.isMobile
          ? AppBar(
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
              title: Text(TranslationKey.sendFile.tr),
            )
          : null,
      body: Column(
        children: [
          if(Platform.isMacOS)
            const SizedBox(height: 25),
          SizedBox(
            height: 155,
            child: Obx(
              () => buildOnlineDevices(),
            ),
          ),
          Expanded(
            child: DropTarget(
              child: Obx(() => buildPendingItems()),
              onDragDone: (detail) {
                pendingFileService.addDropItems(detail.files);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Obx(
        () => Visibility(
          visible: pendingFileService.pendingItems.isNotEmpty,
          child: FloatingActionButton(
            tooltip: TranslationKey.sendFiles.tr,
            onPressed: () async {
              final devices = pendingFileService.pendingDevs;
              if (devices.isEmpty) {
                Global.showTipsDialog(context: context, text: TranslationKey.pleaseSelectDevices.tr);
                return;
              }
              onSendClicked(devices.toList(growable: false), pendingFileService.pendingItems);
            },
            child: Transform.rotate(
              angle: -45 * (pi / 180),
              child: const Icon(Icons.send),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildOnlineDevices() {
    //如果只有一个设备，默认选择
    if (devices.length == 1) {
      pendingFileService.pendingDevs.add(devices[0]);
    }
    final selectedDevs = pendingFileService.pendingDevs.toList(growable: false);
    return OnlineDevices(
      direction: Axis.horizontal,
      onlineList: devices,
      selectedList: selectedDevs,
      onTap: (dev) {
        final selected = selectedDevs.contains(dev);
        if (selected) {
          pendingFileService.pendingDevs.remove(dev);
        } else {
          pendingFileService.pendingDevs.add(dev);
        }
      },
    );
  }

  Widget buildPendingItems() {
    //这里不能直接将 `pendingFileService.pendingItems` 传给参数，因为传进去的是RxList，然后组件内部引用了但是没有使用Obx包裹就会报错
    final items = pendingFileService.pendingItems.toList(growable: false);
    return PendingFileList(
      pendingItems: items,
      onItemRemove: onItemRemove,
      onAddClicked: () async {
        var result = await FileUtil.pickFiles();
        final files = result.map((f) => DropItemFile(f.path!)).toList();
        pendingFileService.addDropItems(files);
      },
      onClearAllClicked: () {
        pendingFileService.clearPendingInfo();
      },
    );
  }
}
