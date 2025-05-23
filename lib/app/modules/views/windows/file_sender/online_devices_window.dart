import 'dart:convert';

import 'package:clipshare/app/data/enums/channelMethods/multi_window_method.dart';
import 'package:clipshare/app/data/enums/multi_window_tag.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/repository/entity/tables/device.dart';
import 'package:clipshare/app/listeners/window_control_clicked_listener.dart';
import 'package:clipshare/app/modules/views/windows/file_sender/online_devices_page.dart';
import 'package:clipshare/app/services/channels/multi_window_channel.dart';
import 'package:clipshare/app/services/pending_file_service.dart';
import 'package:clipshare/app/services/window_control_service.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:window_manager/window_manager.dart';

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

class _FileSenderWindowState extends State<FileSenderWindow> with WidgetsBindingObserver, WindowControlClickedListener {
  List<Device> _devices = [];
  final multiWindowChannelService = Get.find<MultiWindowChannelService>();
  final pendingFileService = Get.find<PendingFileService>();
  final windowControlService = Get.find<WindowControlService>();

  @override
  void initState() {
    super.initState();
    windowControlService.addListener(this);
    //监听生命周期
    WidgetsBinding.instance.addObserver(this);
    if (widget.args.containsKey("files")) {
      var files = widget.args["files"] as List<dynamic>;
      addPendingFiles(files.cast<String>());
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
        //关闭（隐藏）窗口
        case MultiWindowMethod.showWindowFromHide:
          var position = args["position"];
          if (position != null) {
            var [x, y] = (position as List<dynamic>).cast<double>();
            windowManager.setPosition(Offset(x, y));
          }
          widget.windowController.show();
          windowManager.setAlwaysOnTop(true);
          var otherArgs = args["args"] as Map<String, dynamic>;
          var files = otherArgs["files"] as List<dynamic>;
          addPendingFiles(files.cast<String>());
          refresh();
          break;
        //关闭（隐藏）窗口
        case MultiWindowMethod.closeWindow:
          widget.windowController.hide();
          pendingFileService.clearPendingInfo();
          break;
        default:
      }
      //都不符合，返回空
      return Future.value();
    });
    refresh();
  }

  void addPendingFiles(List<String> filePaths) {
    pendingFileService.addDropItems(filePaths.map((path) => DropItemFile(path)).toList());
  }

  @override
  void onCloseBtnClicked() {
    multiWindowChannelService.closeWindow(0, MultiWindowTag.history);
  }

  @override
  void dispose() {
    super.dispose();
    windowControlService.removeListener(this);
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
