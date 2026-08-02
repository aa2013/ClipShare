import 'dart:async';
import 'dart:convert';

import 'package:clipshare/app/data/enums/channelMethods/multi_window_method.dart';
import 'package:clipshare/app/data/enums/multi_window_tag.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/enums/window_type.dart';
import 'package:clipshare/app/data/models/my_drop_item.dart';
import 'package:clipshare/app/data/repository/entity/tables/device.dart';
import 'package:clipshare/app/listeners/window_control_clicked_listener.dart';
import 'package:clipshare/app/modules/views/windows/file_sender/online_devices_page.dart';
import 'package:clipshare/app/services/channels/multi_window_channel.dart';
import 'package:clipshare/app/services/multi_window_config_service.dart';
import 'package:clipshare/app/services/multi_window_dispatch_service.dart';
import 'package:clipshare/app/services/pending_file_service.dart';
import 'package:clipshare/app/services/window_control_service.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
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

class _FileSenderWindowState extends State<FileSenderWindow> with WindowListener, WidgetsBindingObserver, WindowControlClickedListener implements MultiWindowMessageListener {
  List<Device> _devices = [];
  final multiWindowChannelService = Get.find<MultiWindowChannelService>();
  final multiWindowConfigService = Get.find<MultiWindowConfigService>();
  final pendingFileService = Get.find<PendingFileService>();
  final windowControlService = Get.find<WindowControlService>();

  @override
  void initState() {
    super.initState();
    windowControlService.addListener(this);
    //监听生命周期
    WidgetsBinding.instance.addObserver(this);
    multiWindowMsgDispatchService.addListener(this);
    windowManager.addListener(this);
    if (widget.args.containsKey("files")) {
      var files = widget.args["files"] as List<dynamic>;
      addPendingFiles(files.cast<String>());
    }
    refresh();
  }

  @override
  FutureOr<void> onMultiWindowMessage(MultiWindowMethod method, Map<String, dynamic> args, int fromWindowId) {
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
  }

  @override
  Future<void> onWindowResized() async {
    super.onWindowResized();
    final size = await windowManager.getSize();
    await multiWindowChannelService.updateWindowSize(0, WindowType.fileSender, size);
  }

  @override
  /// 子窗口失焦时按统一偏好决定是否自动隐藏，确保待发送列表清理时机与手动关闭一致。
  void onWindowBlur() {
    if (!multiWindowConfigService.autoClosePopupOnBlur) {
      return;
    }
    // 文件传输弹窗失焦后也走统一隐藏入口，确保待发送状态清理逻辑保持一致。
    multiWindowChannelService.closeWindow(0, widget.windowController.windowId, MultiWindowTag.devices);
  }

  void addPendingFiles(List<String> filePaths) {
    pendingFileService.addDropItems(filePaths.map((path) => DropItemFile(path)).toList());
  }

  @override
  void onCloseBtnClicked(bool isHide) {
    multiWindowChannelService.closeWindow(0, widget.windowController.windowId, MultiWindowTag.devices);
  }

  @override
  void dispose() {
    super.dispose();
    windowControlService.removeListener(this);
    windowManager.removeListener(this);
    multiWindowMsgDispatchService.removeListener(this);
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
