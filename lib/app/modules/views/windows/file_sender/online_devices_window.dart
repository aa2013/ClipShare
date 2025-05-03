import 'dart:convert';

import 'package:clipshare/app/data/enums/channelMethods/multi_window_method.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/repository/entity/tables/device.dart';
import 'package:clipshare/app/modules/views/windows/file_sender/online_devices_page.dart';
import 'package:clipshare/app/services/channels/multi_window_channel.dart';
import 'package:clipshare/app/services/pending_file_service.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class FileSenderWindow extends StatefulWidget {
  final WindowController windowController;
  final Map args;

  const FileSenderWindow({
    super.key,
    required this.windowController,
    required this.args,
  });

  @override
  State<StatefulWidget> createState() {
    return _FileSenderWindowState();
  }
}

class _FileSenderWindowState extends State<FileSenderWindow> with WidgetsBindingObserver {
  List<Device> _devices = [];
  final multiWindowChannelService = Get.find<MultiWindowChannelService>();
  final pendingFileService = Get.find<PendingFileService>();

  @override
  void initState() {
    super.initState();
    //监听生命周期
    WidgetsBinding.instance.addObserver(this);
    if (widget.args.containsKey("files")) {
      var files = widget.args["files"] as List<dynamic>;
      pendingFileService.addDropItems(files.cast<String>().map((path) => DropItemFile(path)).toList());
    }
    //处理弹窗事件
    DesktopMultiWindow.setMethodHandler((
      MethodCall call,
      int fromWindowId,
    ) async {
      var args = jsonDecode(call.arguments);
      var method = MultiWindowMethod.values.byName(call.method);
      switch (method) {
        //更新通知
        case MultiWindowMethod.notify:
          refresh();
          break;
        default:
      }
      //都不符合，返回空
      return Future.value();
    });
    refresh();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.inactive:
        // widget.windowController.close();
        break;
      default:
    }
  }

  void refresh() async {
    var json = await multiWindowChannelService.getCompatibleOnlineDevices(0);
    var data = (jsonDecode(json) as List<dynamic>).cast<Map<String, dynamic>>();
    List<Device> devices = List.empty(growable: true);
    for (var dev in data) {
      devices.add(Device.fromJson(dev));
    }
    _devices = devices;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return FileSenderPage(
      devices: _devices,
      onSendClicked: (List<Device> devices, List<DropItem> items) async {
        await multiWindowChannelService.syncFiles(
          0,
          devices,
          items.map((item) => item.path).toList(growable: false),
        );
        Global.showSnackBarSuc(
          text: TranslationKey.startSendFileToast.tr,
          context: context,
        );
        pendingFileService.clearPendingInfo();
      },
      onItemRemove: (DropItem item) {
        pendingFileService.removeDropItem(item);
      },
    );
  }
}
