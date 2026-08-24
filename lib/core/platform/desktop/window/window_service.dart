import 'dart:io';

import 'package:clipshare/core/constants/platform_constants.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:window_manager/window_manager.dart';

/// 主窗口生命周期服务。
///
/// 负责接管系统关闭行为、显示主窗口以及安全退出应用。
class WindowService with WindowListener {
  static const tag = 'WindowService';

  /// 是否记住上次窗口尺寸。
  final bool Function() rememberWindowSize;

  /// 是否接管 Win+V。
  final bool Function() takeOverWinV;

  /// 退出时是否恢复 Win+V。
  final bool Function() restoreWinVOnExit;

  bool _initialized = false;

  WindowService({
    required this.rememberWindowSize,
    required this.takeOverWinV,
    required this.restoreWinVOnExit,
  });

  /// 初始化窗口监听与关闭拦截。
  Future<void> init() async {
    if (_initialized) {
      return;
    }
    _initialized = true;
    windowManager.addListener(this);
    await windowManager.setPreventClose(true);
  }

  /// 释放窗口监听。
  void dispose() {
    windowManager.removeListener(this);
  }

  /// 显示主窗口，并恢复 macOS 任务栏显示。
  Future<void> showApp() async {
    if (isMacOS) {
      await windowManager.setSkipTaskbar(false);
    }
    await windowManager.setPreventClose(true);
    await windowManager.show();
  }

  /// 安全退出应用。
  Future<void> exitApp() async {
    await windowManager.setPreventClose(false);
    await windowManager.hide();
    await windowManager.close();
    exit(0);
  }

  @override
  void onWindowClose() {
    // 主窗口点击关闭按钮时只隐藏到托盘，不直接退出进程。
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
    // 这里仅触发一次尺寸查询，后续接入持久化配置后再写回设置。
    await windowManager.getSize();
  }
}
