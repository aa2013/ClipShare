import 'dart:io';
import 'dart:ui';

import 'package:clipshare/core/constants/platform_constants.dart';
import 'package:clipshare/core/database/app_database.dart';
import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/platform/desktop/hotkey/hot_key_provider.dart';
import 'package:clipshare/core/settings/preference/preference_settings_provider.dart';
import 'package:clipshare/shared/enums/config_key.dart';
import 'package:clipshare/shared/extensions/size_extension.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:window_manager/window_manager.dart';

part 'window_provider.g.dart';

/// 主窗口生命周期服务。
///
/// 负责接管系统关闭行为、显示主窗口以及安全退出应用。
@Riverpod(keepAlive: true)
class WindowNotifier extends _$WindowNotifier with WindowListener {
  static const tag = 'WindowNotifier';

  HotKeyNotifier get _hotKeyService => ref.read(hotKeyProvider.notifier);

  AppDatabase get _db => ref.read(appDbProvider).requireValue;

  bool get _rememberWindowSize =>
      ref.read(preferenceSettingsProvider).value?.rememberWindowSize ?? false;

  bool _initialized = false;

  @override
  Future<void> build() async {
    ref.onDispose(_dispose);
    if (!isDesktop) {
      return;
    }
    await _init();
  }

  /// 初始化窗口监听与关闭拦截。
  Future<void> _init() async {
    if (_initialized) {
      return;
    }
    _initialized = true;
    windowManager.addListener(this);
    await windowManager.setPreventClose(true);
  }

  /// 释放窗口监听。
  void _dispose() {
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
    // 释放全部热键并按用户设置恢复 Win+V，须在退出进程前完成
    await _hotKeyService.releaseBeforeExit();
    //todo 退出前关闭历史弹窗/文件发送子窗口，待多窗口功能迁移完成后恢复
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
    if (!_rememberWindowSize) {
      return;
    }
    final size = await windowManager.getSize();
    await _saveWindowSize(size);
  }

  /// 保存窗口尺寸到配置并刷新偏好设置缓存。
  Future<void> _saveWindowSize(Size size) async {
    await _db.configDao.addOrUpdate(ConfigKey.windowSize, size.str);
    ref.invalidate(preferenceSettingsProvider);
  }
}
