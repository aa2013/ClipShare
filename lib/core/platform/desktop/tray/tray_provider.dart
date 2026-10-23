import 'dart:async';

import 'package:clipshare/core/constants/app_constants.dart';
import 'package:clipshare/core/constants/platform_constants.dart';
import 'package:clipshare/core/platform/desktop/hotkey/hot_key_provider.dart';
import 'package:clipshare/core/platform/desktop/window/window_provider.dart';
import 'package:clipshare/core/services/device/device_provider.dart';
import 'package:clipshare/core/services/device/events/device_lifecycle_event.dart';
import 'package:clipshare/core/settings/hotkey/hotkey_settings.dart';
import 'package:clipshare/core/settings/hotkey/hotkey_settings_provider.dart';
import 'package:clipshare/l10n/l10n_provider.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/constants/assets.dart';
import 'package:clipshare/shared/extensions/keyboard_key_extension.dart';
import 'package:clipshare/shared/extensions/number_extension.dart';
import 'package:clipshare/shared/utils/hotkey_util.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tray_manager/tray_manager.dart';

part 'tray_provider.g.dart';

/// 桌面端系统托盘服务。
@Riverpod(keepAlive: true)
class TrayNotifier extends _$TrayNotifier with TrayListener {
  static const tag = 'TrayNotifier';

  /// 托盘菜单项 key：显示主窗口
  static const menuKeyShowWindow = 'show_window';

  /// 托盘菜单项 key：退出应用
  static const menuKeyExitApp = 'exit_app';

  HotkeySettings get _hotKeySettings => ref.read(hotkeySettingsProvider).requireValue;

  WindowNotifier get _windowService => ref.read(windowProvider.notifier);

  DeviceState get _deviceState => ref.read(deviceProvider).requireValue;

  DeviceNotifier get _deviceNotifier => ref.read(deviceProvider.notifier);

  HotKeyNotifier get _hotKeyService => ref.read(hotKeyProvider.notifier);

  bool _initialized = false;
  bool _trayClick = false;
  bool _flashing = false;
  Timer? _tooltipTimer;
  StreamSubscription<DeviceLifecycleEvent>? _deviceLifecycleSubscription;

  String get _warningIconPath {
    if (isWindows) {
      return logoWarnIcoPath;
    }
    return logoWarnPngPath;
  }

  String get _normalIconPath {
    if (isWindows) {
      return logoIcoPath;
    }
    return logoPngPath;
  }

  @override
  Future<void> build() async {
    ref.onDispose(_dispose);
    if (!isDesktop) {
      return;
    }
    await _init();
    ref.listen(
      hotkeySettingsProvider,
      (previous, next) => updateTrayMenus(),
    );
    ref.listen(uiLocaleProvider, (previous, next) => updateTrayMenus());
  }

  /// 初始化托盘
  Future<void> _init() async {
    if (_initialized) {
      return;
    }
    await setToolTip(appName);
    await _resetIcon();
    await updateTrayMenus();
    _deviceLifecycleSubscription = _deviceNotifier.lifecycleEvents.listen(_watchDevAlive);
    trayManager.addListener(this);
    _initialized = true;
  }

  void _watchDevAlive(DeviceLifecycleEvent event) {
    _tooltipTimer?.cancel();
    _tooltipTimer = Timer(1.s, (){
      _updateDevAliveTooltip(appName);
    });
  }


  Future<void> _resetIcon() async {
    String iconPath = _warningIconPath;
    try {
      final onlineList = _deviceState.onlineAndPairedList;
      if (onlineList.isNotEmpty) {
        iconPath = _normalIconPath;
      }
    } catch (_) {
      //ignored
    }
    await trayManager.setIcon(id: isLinux ? appName : null, iconPath);
    await setToolTip(appName);
  }

  /// 释放托盘监听
  void _dispose() {
    trayManager.removeListener(this);
    _deviceLifecycleSubscription?.cancel();
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

  /// 重建托盘右键菜单
  /// [registerKey] 为 true 时同时注册显示主窗口与退出程序热键。
  Future<void> updateTrayMenus([bool registerKey = true]) async {
    final showHotKeys = _hotKeySettings.showMainWindows;
    final exitHotKeys = _hotKeySettings.exitAppHotKeys;
    var showWindowLabel = _menuLabel(TranslationKey.showMainWindow.tr, _hotKeyDesc(showHotKeys));
    var exitAppLabel = _menuLabel(TranslationKey.exitApp.tr, _hotKeyDesc(exitHotKeys));
    List<MenuItem> items = [
      MenuItem(
        key: menuKeyShowWindow,
        label: showWindowLabel,
      ),
      MenuItem.separator(),
      MenuItem(
        key: menuKeyExitApp,
        label: exitAppLabel,
      ),
    ];
    await trayManager.setContextMenu(Menu(items: items));
    if (registerKey) {
      try {
        if (showHotKeys.isNotEmpty) {
          await _hotKeyService.registerShowMainWindow(toSystemHotKey(showHotKeys));
        }
      } catch (err, stack) {
        logger.error(tag, err, stack);
      }
      try {
        if (exitHotKeys.isNotEmpty) {
          await _hotKeyService.registerExitApp(toSystemHotKey(exitHotKeys));
        }
      } catch (err, stack) {
        logger.error(tag, err, stack);
      }
    }
  }

  /// 热键码串转换为展示文本，转换失败时返回空串。
  String _hotKeyDesc(String keyCodes) {
    if (keyCodes.isEmpty) {
      return '';
    }
    try {
      return toSystemHotKey(keyCodes).desc;
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
    final onlineList = _deviceState.onlineList;
    final pairedDevIds = _deviceState.pairedList.map((device)=>device.guid).toSet();
    var pairedCnt = 0;
    var unpairedCnt = 0;
    for (var device in onlineList) {
      if (pairedDevIds.contains(device.guid)) {
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
    await _windowService.showApp();
  }

  /// 退出应用。
  Future<void> exitApp() async {
    await _windowService.exitApp();
  }

  @override
  void onTrayIconMouseDown() {
    //记录是否双击，如果点击了一次，设置trayClick为true，再次点击时验证
    if (_trayClick) {
      _trayClick = false;
      unawaited(showWindow());
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
      case menuKeyShowWindow:
        showWindow();
        break;
      case menuKeyExitApp:
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
