import 'dart:async';
import 'dart:io';

import 'package:clipshare/app/data/enums/hot_key_type.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/handlers/hot_key_handler.dart';
import 'package:clipshare/app/listeners/dev_alive_listener.dart';
import 'package:clipshare/app/modules/device_module/device_controller.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/transport/connection_registry_service.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/extensions/number_extension.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:get/get.dart';
import 'package:tray_manager/tray_manager.dart';

import 'window_service.dart';

class TrayService extends GetxService with TrayListener, DevAliveListener {
  bool _trayClick = false;
  static const tag = "TrayService";
  final windowService = Get.find<WindowService>();
  final appConfig = Get.find<ConfigService>();
  final connRegService = Get.find<ConnectionRegistryService>();
  Timer? _tooltipTimer;

  Future<TrayService> init() async {
    await _initTrayManager();
    connRegService.addDevAliveListener(this);
    return this;
  }

  ///初始化托盘
  Future<void> _initTrayManager() async {
    trayManager.addListener(this);
    await setToolTip(Constants.appName);
    await _resetIcon();
    updateTrayMenus();
  }

  @override
  FutureOr<void> onConnected(_, _, _, _) {
    _watchDevAlive();
  }

  @override
  void onDisconnected(_) {
    _watchDevAlive();
  }

  @override
  void onPaired(_, _, _, _) {
    _watchDevAlive();
  }

  @override
  void onCancelPairing(_) {
    _watchDevAlive();
  }

  void _watchDevAlive() {
    _tooltipTimer?.cancel();
    _tooltipTimer = Timer(1.s, (){
      _updateDevAliveTooltip(Constants.appName);
    });
  }

  Future<void> _updateDevAliveTooltip(String firstContent) async {
    final devController = Get.find<DeviceController>();
    final onlineList = devController.onlineList;
    var pairedCnt = 0;
    var unpairedCnt = 0;
    for (var dev in onlineList) {
      if (dev.isPaired) {
        pairedCnt++;
      } else {
        unpairedCnt++;
      }
    }
    await setToolTip(
      TranslationKey.trayDevAliveTooltip.trParams({
        "first": firstContent,
        "pairedCnt": pairedCnt.toString(),
        "unpairedCnt": unpairedCnt.toString(),
      }),
    );
  }

  Future<void> setToolTip(String toolTip) async {
    if (!Platform.isLinux) {
      trayManager.setToolTip(toolTip);
    }
  }

  Future<void> _resetIcon() async {
    await trayManager.setIcon(
      Platform.isWindows ? Constants.logoIcoPath : Constants.logoPngPath,
    );
    await setToolTip(Constants.appName);
  }

  Future<void> flashTray(
    String iconAssetPath, {
    Duration? totalDuration,
    Duration? intervalDuration,
    String? toolTip,
  }) async {
    intervalDuration ??= const Duration(milliseconds: 300);
    totalDuration ??= const Duration(seconds: 5);

    final endTime = DateTime.now().add(totalDuration);
    DateTime now;
    if (toolTip != null) {
      await _updateDevAliveTooltip(toolTip);
    }
    do {
      await trayManager.setIcon("");
      await Future.delayed(intervalDuration);

      await trayManager.setIcon(iconAssetPath);
      await Future.delayed(intervalDuration);

      now = DateTime.now();
    } while (now.isBefore(endTime));
    await trayManager.setIcon("");
    await Future.delayed(intervalDuration);
    await _resetIcon();
    await _updateDevAliveTooltip(Constants.appName);
  }

  Future<void> flashTrayWarning([String? toolTip]) async {
    await flashTray(
      Platform.isWindows ? Constants.logoWarnIcoPath : Constants.logoWarnPngPath,
      toolTip: toolTip,
    );
  }

  Future<void> flashTrayNormal([String? toolTip]) async {
    await flashTray(
      Platform.isWindows ? Constants.logoIcoPath : Constants.logoPngPath,
      toolTip: toolTip,
    );
  }

  Future<void> updateTrayMenus([bool registerKey = true]) async {
    final showMainWindowKeys = appConfig.showMainWindowHotKeys;
    final exitAppKeys = appConfig.exitAppHotKeys;
    if (registerKey) {
      try {
        if (showMainWindowKeys.isNotEmpty) {
          await AppHotKeyHandler.registerShowMainWindow(
            AppHotKeyHandler.toSystemHotKey(showMainWindowKeys),
          );
        }
      } catch (err, stack) {
        Log.error(tag, err, stack);
      }
      try {
        if (exitAppKeys.isNotEmpty) {
          await AppHotKeyHandler.registerExitApp(
            AppHotKeyHandler.toSystemHotKey(exitAppKeys),
          );
        }
      } catch (err, stack) {
        Log.error(tag, err, stack);
      }
    }
    var showWindowLabel = '${TranslationKey.showMainWindow.tr}  ${HotKeyType.showMainWindows.hotKeyDesc ?? ""}';
    var exitAppLabel = '${TranslationKey.exitApp.tr}  ${HotKeyType.exitApp.hotKeyDesc ?? ""}';
    List<MenuItem> items = [
      MenuItem(
        key: 'show_window',
        label: showWindowLabel,
      ),
      MenuItem.separator(),
      MenuItem(
        key: 'exit_app',
        label: exitAppLabel,
      ),
    ];
    await trayManager.setContextMenu(Menu(items: items));
  }

  @override
  void onTrayIconRightMouseDown() async {
    await trayManager.popUpContextMenu();
  }

  @override
  void onTrayIconMouseDown() async {
    //记录是否双击，如果点击了一次，设置trayClick为true，再次点击时验证
    if (_trayClick) {
      _trayClick = false;
      windowService.showApp();
      return;
    }
    _trayClick = true;
    // 创建一个延迟0.2秒执行一次的定时器重置点击为false
    Timer(200.ms, () {
      _trayClick = false;
    });
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    Log.debug(tag, '你选择了${menuItem.label}');
    switch (menuItem.key) {
      case 'show_window':
        clickShowWindowItem();
        break;
      case 'exit_app':
        clickExitAppItem();
        break;
    }
  }

  void clickShowWindowItem() {
    windowService.showApp();
  }

  void clickExitAppItem() {
    windowService.exitApp();
  }

  @override
  void onClose() {
    trayManager.removeListener(this);
    connRegService.removeDevAliveListener(this);
    super.onClose();
  }
}
