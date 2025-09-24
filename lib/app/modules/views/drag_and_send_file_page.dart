import 'package:clipshare/app/modules/device_module/device_controller.dart';
import 'package:clipshare/app/modules/home_module/home_controller.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/pending_file_service.dart';
import 'package:clipshare/app/utils/file_util.dart';
import 'package:clipshare/app/widgets/dragAndSendFiles/online_devices.dart';
import 'package:clipshare/app/widgets/dragAndSendFiles/pending_file_list.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class DragAndSendFilePage extends StatefulWidget {
  final void Function(DropItem item) onItemRemove;

  const DragAndSendFilePage({super.key, required this.onItemRemove});

  @override
  State<StatefulWidget> createState() => _DragAndSendFilePageState();
}

class _DragAndSendFilePageState extends State<DragAndSendFilePage> {
  final devController = Get.find<DeviceController>();
  final pendingFileService = Get.find<PendingFileService>();
  final appConfig = Get.find<ConfigService>();
  final homeController = Get.find<HomeController>();

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(handleKeyEvent);
  }

  @override
  void dispose() {
    super.dispose();
    HardwareKeyboard.instance.removeHandler(handleKeyEvent);
  }

  bool handleKeyEvent(KeyEvent event) {
    if (!appConfig.isSmallScreen) {
      if (event.physicalKey == PhysicalKeyboardKey.escape) {
        homeController.showPendingItemsDetail.value = false;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    ///mobile
    if (appConfig.isSmallScreen) {
      return PopScope(
        canPop: !homeController.showPendingItemsDetail.value,
        onPopInvokedWithResult: (bool didPop, dynamic result) {
          if (!didPop) {
            homeController.showPendingItemsDetail.value = false;
          }
        },
        child: Padding(
          padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
          child: SafeArea(
            child: Column(
              children: [
                SizedBox(height: 155, child: Obx(() => buildOnlineDevices())),
                Expanded(child: Obx(() => buildPendingItems())),
              ],
            ),
          ),
        ),
      );
    }

    ///desktop
    return Padding(
      padding: const EdgeInsets.only(left: 30, right: 30, bottom: 30),
      child: Row(
        children: [
          SizedBox(width: 280, child: Obx(() => buildOnlineDevices())),
          Expanded(child: buildPendingItems()),
        ],
      ),
    );
  }

  Widget buildOnlineDevices() {
    final onlineList = devController.onlineAndPairedList;
    if (onlineList.length == 1) {
      pendingFileService.pendingDevs.add(onlineList[0]);
    }
    return OnlineDevices(
      direction: Axis.vertical,
      onlineList: onlineList,
      selectedList: pendingFileService.pendingDevs.toList(),
      onTap: (dev) {
        final selected = pendingFileService.pendingDevs.contains(dev);
        if (selected) {
          pendingFileService.pendingDevs.remove(dev);
        } else {
          pendingFileService.pendingDevs.add(dev);
        }
      },
    );
  }

  Widget buildPendingItems() {
    return PendingFileList(
      pendingItems: pendingFileService.pendingItems.toList(),
      onItemRemove: widget.onItemRemove,
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
