import 'dart:async';

import 'package:clipshare/core/constants/app_constants.dart';
import 'package:clipshare/core/constants/platform_constants.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/constants/assets.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:tray_manager/tray_manager.dart';

/// 桌面端系统托盘服务。
class TrayService with TrayListener/* todo , DevAliveListener*/ {
  static const tag = 'TrayService';
  /// 托盘菜单项 key：显示主窗口
  static const menuKeyShowWindow = 'show_window';

  /// 托盘菜单项 key：退出应用
  static const menuKeyExitApp = 'exit_app';

  /// "显示主窗口"热键配置取值器（每次读取最新值）
  final String Function() showHotKeys;

  /// "退出应用"热键配置取值器（每次读取最新值）
  final String Function() exitHotKeys;

  /// "显示主窗口"动作实现
  final Future<void> Function() doShowWindow;

  /// "退出应用"动作实现
  final Future<void> Function() doExitApp;

  bool _trayClick = false;
  bool _flashing = false;

  String get _warningIconPath {
    if(isWindows){
      return logoWarnIcoPath;
    }
    return logoWarnPngPath;
  }

  String get _normalIconPath {
    if(isWindows){
      return logoIcoPath;
    }
    return logoPngPath;
  }

  bool _initialized = false;

  TrayService({
    required this.showHotKeys,
    required this.exitHotKeys,
    required this.doShowWindow,
    required this.doExitApp,
  });

  /// 初始化托盘（幂等）：完成监听注册等框架接线。
  Future<void> init() async {
    if (_initialized) {
      return;
    }
    await setToolTip(appName);
    await _resetIcon();
    await updateTrayMenus();
    //TODO
    // connRegService.addDevAliveListener(this);
    trayManager.addListener(this);
    _initialized = true;
  }

  Future<void> _resetIcon() async {
    String iconPath = _warningIconPath;
    try{
      //todo
      // final devController = Get.find<DeviceController>();
      final onlineList = [];//devController.onlineAndPairedList;
      if(onlineList.isNotEmpty){
        iconPath = _normalIconPath;
      }
    }catch(_){
      //ignored
    }
    await trayManager.setIcon(
        id: isLinux ? appName : null,
        iconPath
    );
    await setToolTip(appName);
  }
  /// 释放托盘监听；防抖定时器清理随 tooltip 逻辑一并迁移。
  void dispose() {
    trayManager.removeListener(this);
  }

  /// 设置托盘 tooltip。
  Future<void> setToolTip(String toolTip) async {
    // Linux 无 tooltip 能力，改为 setTitle 展示应用名。
    if (!isLinux) {
      await trayManager.setToolTip(toolTip);
    } else {
      await trayManager.setTitle(appName);
    }
  }

  /// 依据当前热键配置重建托盘右键菜单。
  ///
  /// 由 provider 在热键配置/语言变化时自动触发，外部无需手动调用；
  /// 系统级热键注册职责不属于本服务（归热键模块）。
  Future<void> updateTrayMenus() async {
    final showMainWindowKeys = showHotKeys();
    final exitAppKeys = exitHotKeys();
    var showWindowLabel = _menuLabel(TranslationKey.showMainWindow.tr, _hotKeyDesc(showMainWindowKeys));
    var exitAppLabel = _menuLabel(TranslationKey.exitApp.tr, _hotKeyDesc(exitAppKeys));
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
    //todo
    // if (registerKey) {
    //   try {
    //     if (showMainWindowKeys.isNotEmpty) {
    //       await AppHotKeyHandler.registerShowMainWindow(AppHotKeyHandler.toSystemHotKey(showMainWindowKeys));
    //     }
    //   } catch (err, stack) {
    //     logger.error(tag, err, stack);
    //   }
    //   try {
    //     if (exitAppKeys.isNotEmpty) {
    //       await AppHotKeyHandler.registerExitApp(AppHotKeyHandler.toSystemHotKey(exitAppKeys));
    //     }
    //   } catch (err, stack) {
    //     logger.error(tag, err, stack);
    //   }
    // }
  }

  String _hotKeyDesc(String keyCodes) {
    if (keyCodes.isEmpty) {
      return '';
    }
    try {
      //todo
      // return AppHotKeyHandler.toSystemHotKey(keyCodes).desc;
      return '';
    } catch (err, stack) {
      logger.error(tag, err, stack);
      return '';
    }
  }

  String _menuLabel(String label, String hotKeyDesc) {
    return hotKeyDesc.isEmpty ? label : '$label  $hotKeyDesc';
  }

  /// 以正常态图标闪烁托盘，用于提示设备连接成功等事件。
  Future<void> flashTrayNormal([String? toolTip]) async {
    await flashTray(
      _normalIconPath,
      toolTip: toolTip,
    );
  }

  /// 以警告态图标闪烁托盘，用于提示连接断开等异常事件。
  Future<void> flashTrayWarning([String? toolTip]) async {
    await flashTray(
      _warningIconPath,
      toolTip: toolTip,
    );
  }

  /// 图标闪烁核心流程；结束后必须恢复原图标，避免停留在清空状态。
  Future<void> flashTray(
    String iconAssetPath, {
    Duration? totalDuration,
    Duration? intervalDuration,
    String? toolTip,
  }) async {
    intervalDuration ??= const Duration(milliseconds: 300);
    totalDuration ??= const Duration(seconds: 5);

    if (_flashing) {
      return;
    }
    _flashing = true;
    try {
      final endTime = DateTime.now().add(totalDuration);
      DateTime now;
      if (toolTip != null) {
        await _updateDevAliveTooltip(toolTip);
      }
      do {
        await trayManager.setIcon('');
        await Future.delayed(intervalDuration);

        await trayManager.setIcon(iconAssetPath);
        await Future.delayed(intervalDuration);

        now = DateTime.now();
      } while (now.isBefore(endTime));
    } finally {
      // 无论闪烁是否异常中断，都必须恢复托盘图标，否则 setIcon("") 会
      // 把图标清空并停留在消失状态（任务栏找不到图标）。
      _flashing = false;
      await trayManager.setIcon('');
      await Future.delayed(intervalDuration);
      await _resetIcon();
      await _updateDevAliveTooltip(appName);
    }
  }

  Future<void> _updateDevAliveTooltip(String firstContent) async {
    // final devController = Get.find<DeviceController>();
    final onlineList = [];// todo devController.onlineList;
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
        'first': firstContent,
        'pairedCnt': pairedCnt.toString(),
        'unpairedCnt': unpairedCnt.toString(),
      }),
    );
    if (pairedCnt <= 0) {
      await trayManager.setIcon(_warningIconPath);
    } else {
      await trayManager.setIcon(_normalIconPath);
    }
  }

  /// 显示主窗口并聚焦。
  Future<void> showWindow() async {
    await doShowWindow();
  }

  /// 退出应用。
  Future<void> exitApp() async {
    await doExitApp();
  }

  @override
  void onTrayIconMouseDown() {
    //记录是否双击，如果点击了一次，设置trayClick为true，再次点击时验证
    if (_trayClick) {
      _trayClick = false;
      unawaited(doShowWindow());
      return;
    }
    _trayClick = true;
    // 创建一个延迟0.2秒执行一次的定时器重置点击为false
    Timer(const Duration(milliseconds: 200), () {
      _trayClick = false;
    });
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'show_window':
        showWindow();
        break;
      case 'exit_app':
        exitApp();
        break;
    }
  }

  @override
  Future<void> onTrayIconRightMouseDown() async {
    if (isLinux) {
      await updateTrayMenus();
      return;
    }
    await trayManager.popUpContextMenu();
  }
}
