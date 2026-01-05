import 'dart:async';
import 'dart:io';

import 'package:clipshare/app/data/enums/hot_key_type.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/handlers/hot_key_handler.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/extensions/number_extension.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
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
    trayManager.setToolTip(Constants.appName);
    await trayManager.setIcon(
      Platform.isWindows ? Constants.logoIcoPath : Constants.logoPngPath,
    );
    updateTrayMenus();
  }

  Future<void> updateTrayMenus([bool registerKey = true]) async {
    final showMainWindowKeys = appConfig.showMainWindowHotKeys;
    final exitAppKeys = appConfig.exitAppHotKeys;
    if (registerKey) {
      try {
        if (showMainWindowKeys.isNotEmpty) {
          await AppHotKeyHandler.registerShowMainWindow(AppHotKeyHandler.toSystemHotKey(showMainWindowKeys));
        }
      } catch (err, stack) {
        Log.error(tag, "$err,$stack");
      }
      try {
        if (exitAppKeys.isNotEmpty) {
          await AppHotKeyHandler.registerExitApp(AppHotKeyHandler.toSystemHotKey(exitAppKeys));
        }
      } catch (err, stack) {
        Log.error(tag, "$err,$stack");
      }
    }
    var showWindowLabel = '${TranslationKey.showMainWindow.tr}  ${HotKeyType.showMainWindows.hotKeyDesc ?? ""}';
    debugPrint(showWindowLabel);
    List<MenuItem> items = [
      MenuItem(
        key: 'show_window',
        label: showWindowLabel,
      ),
      MenuItem.separator(),
      MenuItem(
        key: 'exit_app',
        label: '${TranslationKey.exitApp.tr}  ${HotKeyType.exitApp.hotKeyDesc ?? ""}',
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
    super.onClose();
  }
}
