import 'dart:convert';
import 'dart:ui';

import 'package:clipshare/app/data/enums/channelMethods/multi_window_method.dart';
import 'package:clipshare/app/data/enums/multi_window_config.dart';
import 'package:clipshare/app/data/enums/multi_window_tag.dart';
import 'package:clipshare/app/data/enums/window_type.dart';
import 'package:clipshare/app/data/models/search_filter.dart';
import 'package:clipshare/app/data/repository/entity/tables/app_info.dart';
import 'package:clipshare/app/data/repository/entity/tables/device.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/utils/extensions/platform_extension.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:get/get.dart';
import 'package:window_manager/window_manager.dart';

class MultiWindowChannelService extends GetxService {
  static const tag = "MultiWindowChannelService";
  final _hideWindowIds = <int>{};

  ///显示弹窗（从隐藏状态恢复）
  Future showWindowFromHide(
    int targetWindowId, {
    List<double>? position,
    Map<String, dynamic>? args,
  }) {
    if (!PlatformExt.isDesktop) return Future.value();
    Map<String, dynamic> data = {
      "position": position,
    };
    if (args != null) {
      data["args"] = args;
    }
    _hideWindowIds.remove(targetWindowId);
    return DesktopMultiWindow.invokeMethod(
      targetWindowId,
      MultiWindowMethod.showWindowFromHide.name,
      jsonEncode(data),
    );
  }

  ///关闭（隐藏）弹窗
  Future closeWindow(
    int targetWindowId,
    int closeWindowId,
    MultiWindowTag tag,
  ) async {
    if (!PlatformExt.isDesktop) return Future.value();
    try {
      // windowManager.hide() 是 async 方法，必须 await 才能真正捕获其异常；
      // 未 await 的 Future error 不会被同步 try-catch 捕获，会变成 unhandled async error。
      await windowManager.hide();
    } catch (_) {
      // 子窗口中 windowManager.hide() 可能失败，但状态同步不能因此中断。
    }
    _hideWindowIds.add(closeWindowId);
    return DesktopMultiWindow.invokeMethod(
      targetWindowId,
      MultiWindowMethod.closeWindow.name,
      jsonEncode({
        "tag": tag.name,
        "closeWindowId": closeWindowId,
      }),
    );
  }

  void addHideWindow(int windowId) {
    _hideWindowIds.add(windowId);
  }

  bool isHideWindow(int? windowId) {
    return _hideWindowIds.contains(windowId);
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

  ///获取所有 app 信息
  Future<List<AppInfo>> getAllSources(int targetWindowId) async {
    if (!PlatformExt.isDesktop) return Future(() => []);
    final json = await DesktopMultiWindow.invokeMethod(
      targetWindowId,
      MultiWindowMethod.getAllSources.name,
      "{}",
    );
    var lst = (jsonDecode(json) as List<dynamic>).cast<Map<String, dynamic>>();
    return lst.map(AppInfo.fromJson).toList(growable: false);
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


  ///通知主窗体复制
  Future copyContent(int targetWindowId, String content) {
    if (!PlatformExt.isDesktop) return Future(() => false);
    return DesktopMultiWindow.invokeMethod(
      targetWindowId,
      MultiWindowMethod.copyContent.name,
      jsonEncode({"content": content}),
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

  ///通知窗体更新基础数据，如所有的设备信息，所有的标签信息，所有的来源信息
  Future updateAllBaseData(int targetWindowId) {
    return DesktopMultiWindow.invokeMethod(
      targetWindowId,
      MultiWindowMethod.updateAllBaseData.name,
      jsonEncode({}),
    );
  }

  ///更新窗体尺寸
  Future<void> updateWindowSize(
    int targetWindowId,
    WindowType windowType,
    Size size,
  ) {
    return DesktopMultiWindow.invokeMethod(
      targetWindowId,
      MultiWindowMethod.updateWindowSize.name,
      jsonEncode({
        "size": "${size.width}x${size.height}",
        "type": windowType.name,
      }),
    );
  }

  ///弹窗中更新置顶状态
  Future<void> updateHistoryTop(int targetWindowId, int id, bool isTop) {
    return DesktopMultiWindow.invokeMethod(
      targetWindowId,
      MultiWindowMethod.updateHistoryTop.name,
      jsonEncode({
        "id": id,
        "isTop": isTop,
      }),
    );
  }

  ///弹窗中删除一条历史记录
  Future<void> deleteHistory(int targetWindowId, int id) {
    return DesktopMultiWindow.invokeMethod(
      targetWindowId,
      MultiWindowMethod.deleteHistory.name,
      jsonEncode({"id": id}),
    );
  }

  ///更新弹窗配置
  Future<void> updateConfig(
    MultiWindowConfig config,
    dynamic value,
  ) {
    final appConfig = Get.find<ConfigService>();
    var ids = <int>[];
    final historyWindow = appConfig.historyWindow;
    final onlineDevicesWindow = appConfig.onlineDevicesWindow;
    if (historyWindow != null) {
      ids.add(historyWindow.windowId);
    }
    if (onlineDevicesWindow != null) {
      ids.add(onlineDevicesWindow.windowId);
    }
    final futures = <Future>[];
    for (var id in ids) {
      final future = DesktopMultiWindow.invokeMethod(
        id,
        MultiWindowMethod.updateConfig.name,
        jsonEncode({config.name: value}),
      );
      futures.add(future);
    }
    return Future.wait(futures);
  }
}
