import 'dart:async';
import 'dart:io';

import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/handlers/hot_key_handler.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/extensions/keyboard_key_extension.dart';
import 'package:clipshare/app/utils/extensions/number_extension.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:tray_manager/tray_manager.dart';

import 'window_service.dart';

class TrayService extends GetxService with TrayListener {
  bool _trayClick = false;
  static const tag = "TrayService";
  final windowService = Get.find<WindowService>();
  final appConfig = Get.find<ConfigService>();

  Future<TrayService> init() async {
    await _initTrayManager();
    return this;
  }

  ///初始化托盘
  Future<void> _initTrayManager() async {
    trayManager.addListener(this);
    await _setTrayIcon();
    if (Platform.isLinux) {
      await trayManager.setTitle(Constants.appName);
    } else {
      await trayManager.setToolTip(Constants.appName);
    }
    await updateTrayMenus();
  }

  Future<void> _setTrayIcon() async {
    if (!Platform.isLinux) {
      await trayManager.setIcon(
        Platform.isWindows ? Constants.logoIcoPath : Constants.logoPngPath,
      );
      return;
    }

    final iconPath = [
      File(Platform.resolvedExecutable).parent.path,
      'data',
      'flutter_assets',
      Constants.logoPngPath,
    ].join(Platform.pathSeparator);
    await const MethodChannel('tray_manager').invokeMethod('setIcon', {
      'id': Constants.appName,
      'iconPath': iconPath,
    });
  }

  Future<void> updateTrayMenus([bool registerKey = true]) async {
    final showMainWindowKeys = appConfig.showMainWindowHotKeys;
    final exitAppKeys = appConfig.exitAppHotKeys;
    var showWindowLabel = _menuLabel(
      TranslationKey.showMainWindow.tr,
      _hotKeyDesc(showMainWindowKeys),
    );
    var exitAppLabel = _menuLabel(
      TranslationKey.exitApp.tr,
      _hotKeyDesc(exitAppKeys),
    );
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
  }

  String _hotKeyDesc(String keyCodes) {
    if (keyCodes.isEmpty) {
      return "";
    }
    try {
      return AppHotKeyHandler.toSystemHotKey(keyCodes).desc;
    } catch (err, stack) {
      Log.error(tag, err, stack);
      return "";
    }
  }

  String _menuLabel(String label, String hotKeyDesc) {
    return hotKeyDesc.isEmpty ? label : '$label  $hotKeyDesc';
  }

  @override
  void onTrayIconRightMouseDown() async {
    if (Platform.isLinux) {
      await updateTrayMenus(false);
      return;
    }
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
    super.onClose();
  }
}
