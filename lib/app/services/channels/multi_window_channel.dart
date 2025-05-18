import 'dart:convert';
import 'dart:ui';

import 'package:clipshare/app/data/enums/channelMethods/multi_window_method.dart';
import 'package:clipshare/app/data/enums/multi_window_tag.dart';
import 'package:clipshare/app/data/models/search_filter.dart';
import 'package:clipshare/app/data/repository/entity/tables/device.dart';
import 'package:clipshare/app/utils/extensions/platform_extension.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:get/get.dart';

class MultiWindowChannelService extends GetxService {
  static const tag = "MultiWindowChannelService";

  ///显示弹窗（从隐藏状态恢复）
  Future showWindowFromHide(int targetWindowId, {List<double>? position}) {
    if (!PlatformExt.isDesktop) return Future.value();
    return DesktopMultiWindow.invokeMethod(
      targetWindowId,
      MultiWindowMethod.showWindowFromHide.name,
      jsonEncode({
        "position": position,
      }),
    );
  }

  ///关闭（隐藏）弹窗
  Future closeWindow(int targetWindowId, MultiWindowTag tag) {
    if (!PlatformExt.isDesktop) return Future.value();
    return DesktopMultiWindow.invokeMethod(
      targetWindowId,
      MultiWindowMethod.closeWindow.name,
      jsonEncode({
        "tag": tag.name,
      }),
    );
  }

  ///获取历史数据
  Future getHistories(int targetWindowId, int fromId, SearchFilter filter) {
    if (!PlatformExt.isDesktop) return Future(() => "[]");
    return DesktopMultiWindow.invokeMethod(
      targetWindowId,
      MultiWindowMethod.getHistories.name,
      jsonEncode({
        "fromId": fromId,
        "filter": filter,
      }),
    );
  }

  ///获取所有设备名称
  Future getAllDevices(int targetWindowId) {
    if (!PlatformExt.isDesktop) return Future(() => "[]");
    return DesktopMultiWindow.invokeMethod(
      targetWindowId,
      MultiWindowMethod.getAllDevices.name,
      "{}",
    );
  }

  ///获取所有标签名
  Future getAllTagNames(int targetWindowId) {
    if (!PlatformExt.isDesktop) return Future(() => "[]");
    return DesktopMultiWindow.invokeMethod(
      targetWindowId,
      MultiWindowMethod.getAllTagNames.name,
      "{}",
    );
  }

  ///通知主窗体复制
  Future copy(int targetWindowId, int historyId) {
    if (!PlatformExt.isDesktop) return Future(() => false);
    return DesktopMultiWindow.invokeMethod(
      targetWindowId,
      MultiWindowMethod.copy.name,
      jsonEncode({"id": historyId}),
    );
  }

  ///通知子窗体数据变更
  Future notify(int targetWindowId) {
    if (!PlatformExt.isDesktop) return Future(() => false);
    return DesktopMultiWindow.invokeMethod(
      targetWindowId,
      MultiWindowMethod.notify.name,
      "{}",
    );
  }

  ///获取当前在线的兼容版本设备列表
  Future getCompatibleOnlineDevices(int targetWindowId) {
    if (!PlatformExt.isDesktop) return Future(() => []);
    return DesktopMultiWindow.invokeMethod(
      targetWindowId,
      MultiWindowMethod.getCompatibleOnlineDevices.name,
      "{}",
    );
  }

  ///发送待发送文件和设备列表
  Future syncFiles(
    int targetWindowId,
    List<Device> devices,
    List<String> files,
  ) {
    if (!PlatformExt.isDesktop) return Future.value();
    return DesktopMultiWindow.invokeMethod(
      targetWindowId,
      MultiWindowMethod.syncFiles.name,
      jsonEncode({
        "devices": devices,
        "files": files,
      }),
    );
  }

  ///发送当前窗体的位置给主程序
  Future storeWindowPos(int targetWindowId, String type, Offset pos) {
    return DesktopMultiWindow.invokeMethod(
      targetWindowId,
      MultiWindowMethod.storeWindowPos.name,
      jsonEncode({
        "type": type,
        "pos": "${pos.dx}x${pos.dy}",
      }),
    );
  }
}
