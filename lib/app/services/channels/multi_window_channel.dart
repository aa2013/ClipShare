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
import 'package:desktop_click_outside/desktop_click_outside.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:get/get.dart';
import 'package:window_manager/window_manager.dart';

class MultiWindowChannelService extends GetxService {
  static const tag = "MultiWindowChannelService";
  final _hideWindowIds = <int>{};

  void _setClickOutsideWatch(bool watch) {
    final watcher = DesktopClickOutside.instance;
    Future future;
    if (watch) {
      future = watcher.startWatching(gracePeriod: Duration.zero);
    } else {
      future = watcher.stopWatching();
    }
    future.catchError((_) {});
  }

  ///显示弹窗（从隐藏状态恢复）
  Future showWindowFromHide(
    int targetWindowId, {
    required MultiWindowTag tag,
    List<double>? position,
    Map<String, dynamic>? args,
    bool isRelocate = false,
  }) {
    if (!PlatformExt.isDesktop) return Future.value();
    // 历史弹窗显示时开启共享点击外部监听；设备弹窗不触碰该开关，避免多个弹窗互相踩状态。
    removeHideWindow(targetWindowId, tag);
    Map<String, dynamic> data = {
      "position": position,
      "isRelocate": isRelocate,
    };
    if (args != null) {
      data["args"] = args;
    }
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
    await windowManager.hide();
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

  void addHideWindow(int windowId, MultiWindowTag tag) {
    _hideWindowIds.add(windowId);
    if (tag == MultiWindowTag.history) {
      _setClickOutsideWatch(false);
    }
  }

  ///登记已显示窗口；历史弹窗会同时开启点击外部监听。
  ///首次 createWindow 路径也必须调用，不能只依赖 showWindowFromHide。
  void removeHideWindow(int windowId, MultiWindowTag tag) {
    _hideWindowIds.remove(windowId);
    if (tag == MultiWindowTag.history) {
      _setClickOutsideWatch(true);
    }
  }

  ///主进程隐藏（关闭）指定的子窗口。
  ///
  /// 与 [closeWindow] 不同，这里只通知子窗口隐藏自身并同步主进程的隐藏状态，
  /// 不会调用 windowManager.hide()，避免误隐藏主进程自身的窗口。
  Future hideChildWindow(int windowId, MultiWindowTag tag) async {
    if (!PlatformExt.isDesktop) return Future.value();
    if (isHideWindow(windowId)) return Future.value();
    // 隐藏状态与监听关闭统一走主 isolate 路径。
    addHideWindow(windowId, tag);
    return DesktopMultiWindow.invokeMethod(
      windowId,
      MultiWindowMethod.closeWindow.name,
      jsonEncode({
        "tag": tag.name,
        "closeWindowId": windowId,
      }),
    );
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

  ///同步历史弹窗置顶状态给主窗口（运行期状态，主窗口据此决定点击外部是否关闭弹窗）
  Future setHistoryPinned(bool pinned) {
    if (!PlatformExt.isDesktop) return Future.value();
    return DesktopMultiWindow.invokeMethod(
      0,
      MultiWindowMethod.setHistoryPinned.name,
      jsonEncode({"pinned": pinned}),
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
