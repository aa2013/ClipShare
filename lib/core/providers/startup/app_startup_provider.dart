import 'dart:ui';

import 'package:clipshare/core/clipboard/clipboard_service_provider.dart';
import 'package:clipshare/core/constants/app_constants.dart';
import 'package:clipshare/core/constants/platform_constants.dart';
import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/platform/desktop/tray/tray_service_provider.dart';
import 'package:clipshare/core/platform/desktop/window/window_control_provider.dart';
import 'package:clipshare/core/platform/desktop/window/window_service_provider.dart';
import 'package:clipshare/core/providers/local_device/local_device_info_provider.dart';
import 'package:clipshare/core/providers/settings/app_paths/app_paths_provider.dart';
import 'package:clipshare/core/providers/settings/device/device_settings_provider.dart';
import 'package:clipshare/core/providers/settings/preference/preference_settings_provider.dart';
import 'package:clipshare/core/providers/settings/quick/quick_settings_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:window_manager/window_manager.dart';

part 'app_startup_provider.g.dart';

@riverpod
Future<void> appStartup(Ref ref) async {
  await Future.wait([
    ref.read(appPathsProvider.future),
    ref.read(appDbProvider.future),
    ref.read(deviceSettingsProvider.future),
    ref.read(localDeviceInfoProvider.future),
    ref.read(quickSettingsProvider.future),
    ref.read(preferenceSettingsProvider.future),
    ref.read(clipboardServiceProvider.future),
  ]);
  if (isDesktop) {
    // 窗口服务管理，需先于托盘初始化
    ref.read(windowServiceProvider);
    // 托盘服务
    ref.read(trayServiceProvider);
    // 窗口管理
    await _initWindowsManager(ref);
  }
}

Future<void> _initWindowsManager(Ref ref) async {
  if (!isDesktop) {
    return;
  }
  var preferenceSettings = await ref.read(preferenceSettingsProvider.future);
  final windowOptions = WindowOptions(
    size: preferenceSettings.windowSize,
    minimumSize: kReleaseMode ? const Size(showHistoryRightWidth * 1.0, 200) : null,
    center: true,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );
  final startMini = await ref.read(startMiniProvider.future);
  await ref.read(windowControlProvider.notifier).syncWindowState();
  return windowManager.waitUntilReadyToShow(windowOptions, () async {
    if (!startMini) {
      //非最小化启动
      await windowManager.show();
      await windowManager.focus();
    }
  });
}
