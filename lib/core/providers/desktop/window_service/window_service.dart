import 'dart:io';

import 'package:clipshare/core/constants/platform_constants.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:window_manager/window_manager.dart';

/// 主窗口生命周期服务。
///
/// 负责接管系统关闭行为（点 X 隐藏到托盘而非退出）、显示主窗口、安全退出。
/// 通过 windowServiceProvider 获取 keepAlive 单例；配置以 getter 注入，
/// 每次调用均读取最新值。
class WindowService with WindowListener {
  static const tag = 'WindowService';

  /// 是否记住上次窗口尺寸取值器（每次读取最新值）
  final bool Function() rememberWindowSize;

  /// 是否接管 Win+V 取值器（退出时决定是否需要恢复，每次读取最新值）
  final bool Function() takeOverWinV;

  /// 正常退出前是否恢复 Win+V 取值器（每次读取最新值）
  final bool Function() restoreWinVOnExit;

  bool _initialized = false;

  WindowService({
    required this.rememberWindowSize,
    required this.takeOverWinV,
    required this.restoreWinVOnExit,
  });

  /// 初始化服务
  Future<void> init() async {
    if (_initialized) {
      return;
    }
    _initialized = true;
    windowManager.addListener(this);
    await windowManager.setPreventClose(true);
  }

  /// 释放窗体事件监听
  void dispose() {
    windowManager.removeListener(this);
  }

  /// 显示主窗口
  Future<void> showApp() async {
    if (isMacOS) {
      // macOS 隐藏到托盘时会隐藏任务栏图标，恢复时需先还原。
      await windowManager.setSkipTaskbar(false);
    }
    // 防止后续关闭行为直接退出应用（如托盘菜单外的关闭入口）。
    await windowManager.setPreventClose(true);
    await windowManager.show();
  }

  /// 安全退出应用。
  Future<void> exitApp() async {
    await windowManager.setPreventClose(false);
    //TODO 释放已注册的全局快捷键，确保 Explorer 重启时能重新接管 Win+V
    // await _releaseHotKeysBeforeExit();
    //TODO 按设置在正常退出前恢复 Win+V（takeOverWinV/restoreWinVOnExit），避免接管状态在 Explorer 中长期残留
    // await _restoreWinVBeforeExit();
    //TODO 关闭历史弹窗、在线设备等子窗口（待 multi_window 模块迁移）
    // appConfig.historyWindow?.close();
    // appConfig.onlineDevicesWindow?.close();
    await windowManager.hide();
    await windowManager.close();
    exit(0);
  }

  ///退出前释放应用注册的全局快捷键，确保 Explorer 重启时能重新接管 Win+V。
  Future<void> _releaseHotKeysBeforeExit() async {
    try {
      //todo
      // await AppHotKeyHandler.unRegisterAll();
    } catch (err, stack) {
      logger.error(tag, err, stack);
    }
  }

  ///todo 按用户设置在正常退出前恢复 Win+V，避免接管状态在 Explorer 中长期残留。
  // Future<void> _restoreWinVBeforeExit() async {
  //   if (!Platform.isWindows || !appConfig.takeOverWinV || !appConfig.restoreWinVOnExit) {
  //     return;
  //   }
  //   try {
  //     final changed = await restoreWinV();
  //     if (changed) {
  //       await restartExplorer();
  //     }
  //   } catch (err, stack) {
  //     logger.error(tag, err, stack);
  //   }
  // }

  @override
  void onWindowClose() {
    // 已接管关闭行为：点 X 仅隐藏到托盘，不真正退出。
    windowManager.hide();
    if (isMacOS) {
      windowManager.setSkipTaskbar(true);
    }
    logger.debug(tag, 'main window close intercepted and hidden to tray');
  }

  @override
  Future<void> onWindowResized() async {
    if (!rememberWindowSize()) {
      return;
    }
    //TODO(dev 迁移) preferenceSettings 具备写入能力后持久化窗口尺寸：
    final size = await windowManager.getSize();
    // appConfig.setWindowSize(size);
  }
}
