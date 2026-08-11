import 'dart:async';
import 'dart:io';

import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/handlers/hot_key_handler.dart';
import 'package:clipshare/app/listeners/dev_alive_listener.dart';
import 'package:clipshare/app/modules/device_module/device_controller.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/transport/connection_registry_service.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/extensions/keyboard_key_extension.dart';
import 'package:clipshare/app/utils/extensions/number_extension.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:get/get.dart';
import 'package:tray_manager/tray_manager.dart';

import 'window_service.dart';

class TrayService extends GetxService with TrayListener, DevAliveListener {
  bool _trayClick = false;
  // 托盘闪烁进行中标志：闪烁期间忽略新的闪烁请求，避免并发 setIcon("") 竞态
  // 导致托盘图标最终停留在被清空的状态（fork 版 tray_manager 对空路径
  // LoadImage 失败会 NIM_MODIFY 空图标，把图标从任务栏移除）。
  bool _flashing = false;
  static const tag = "TrayService";
  final windowService = Get.find<WindowService>();
  final appConfig = Get.find<ConfigService>();
  final connRegService = Get.find<ConnectionRegistryService>();
  Timer? _tooltipTimer;
  /// 托盘图标注册重试定时器：启动早期 explorer 托盘区可能未就绪导致
  /// NIM_ADD 静默失败，延迟重试几次覆盖竞态（图标已正常时重试无害）。
  Timer? _trayRetryTimer;

  String get _warningIconPath {
    if(Platform.isWindows){
      //相对路径依赖工作目录（双击运行时 CWD=exe 目录，LoadImage 失败返回 NULL
      //会把图标清空）；改用 exe 目录 + data/flutter_assets 的绝对路径，与 luaLibDirPath 同款
      return _iconAbsPath(Constants.logoWarnIcoPath);
    }
    return Constants.logoWarnPngPath;
  }

  String get _normalIconPath {
    if(Platform.isWindows){
      return _iconAbsPath(Constants.logoIcoPath);
    }
    return Constants.logoPngPath;
  }

  ///拼出 exe 目录下 data/flutter_assets 中资源的绝对路径
  String _iconAbsPath(String assetPath) {
    final execDir = File(Platform.resolvedExecutable).parent.absolute.path;
    final sep = Platform.pathSeparator;
    return '$execDir$sep' 'data$sep' 'flutter_assets$sep${assetPath.replaceAll('/', sep)}';
  }

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
    _retryTrayIcon();
  }

  ///启动早期 explorer 托盘区可能未就绪导致 NIM_ADD 静默失败（无图标），
  ///延迟重试 _resetIcon 覆盖竞态；图标已正常时重试只是 NIM_MODIFY，无害。
  ///定时器为嵌套结构，间隔 2s*attempt，实际触发在启动后累计 2s/6s/12s（共 3 次）。
  void _retryTrayIcon() {
    _trayRetryTimer?.cancel();
    var attempt = 0;
    void tryAgain() {
      attempt++;
      if (attempt > 3) return;
      _trayRetryTimer = Timer(2.s * attempt, () {
        _resetIcon();
        tryAgain();
      });
    }
    tryAgain();
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
    if (pairedCnt <= 0) {
      await trayManager.setIcon(_warningIconPath);
    } else {
      await trayManager.setIcon(_normalIconPath);
    }
  }

  Future<void> setToolTip(String toolTip) async {
    if (!Platform.isLinux) {
      await trayManager.setToolTip(toolTip);
    } else {
      await trayManager.setTitle(Constants.appName);
    }
  }

  Future<void> _resetIcon() async {
    String iconPath = _warningIconPath;
    try{
      final devController = Get.find<DeviceController>();
      final onlineList = devController.onlineAndPairedList;
      if(onlineList.isNotEmpty){
        iconPath = _normalIconPath;
      }
    }catch(_){
      //ignored
    }
    try {
      await trayManager.setIcon(
          id: Platform.isLinux ? Constants.appName : null,
          iconPath
      );
    } catch (e, stack) {
      logger.error(tag, "setIcon failed: $e", stack);
    }
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
        await trayManager.setIcon("");
        await Future.delayed(intervalDuration);

        await trayManager.setIcon(iconAssetPath);
        await Future.delayed(intervalDuration);

        now = DateTime.now();
      } while (now.isBefore(endTime));
    } finally {
      // 无论闪烁是否异常中断，都必须恢复托盘图标，否则 setIcon("") 会
      // 把图标清空并停留在消失状态（任务栏找不到图标）。
      _flashing = false;
      try {
        await trayManager.setIcon("");
        await Future.delayed(intervalDuration);
        await _resetIcon();
        await _updateDevAliveTooltip(Constants.appName);
      } catch (e, stack) {
        logger.error(tag, "flashTray restore failed: $e", stack);
      }
    }
  }

  Future<void> flashTrayWarning([String? toolTip]) async {
    await flashTray(
      _warningIconPath,
      toolTip: toolTip,
    );
  }

  Future<void> flashTrayNormal([String? toolTip]) async {
    await flashTray(
      _normalIconPath,
      toolTip: toolTip,
    );
  }

  Future<void> updateTrayMenus([bool registerKey = true]) async {
    final showMainWindowKeys = appConfig.showMainWindowHotKeys;
    final exitAppKeys = appConfig.exitAppHotKeys;
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

    if (registerKey) {
      try {
        if (showMainWindowKeys.isNotEmpty) {
          await AppHotKeyHandler.registerShowMainWindow(AppHotKeyHandler.toSystemHotKey(showMainWindowKeys));
        }
      } catch (err, stack) {
        logger.error(tag, err, stack);
      }
      try {
        if (exitAppKeys.isNotEmpty) {
          await AppHotKeyHandler.registerExitApp(AppHotKeyHandler.toSystemHotKey(exitAppKeys));
        }
      } catch (err, stack) {
        logger.error(tag, err, stack);
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
      logger.error(tag, err, stack);
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
    logger.debug(tag, '你选择了${menuItem.label}');
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
    _trayRetryTimer?.cancel();
    _tooltipTimer?.cancel();
    super.onClose();
  }
}
