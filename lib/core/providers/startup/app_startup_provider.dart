import 'dart:ui';

import 'package:clipshare/core/constants/app_constants.dart';
import 'package:clipshare/core/constants/platform_constants.dart';
import 'package:clipshare/core/providers/desktop/window_control/window_control_provider.dart';
import 'package:clipshare/core/providers/local_device/local_device_info_provider.dart';
import 'package:clipshare/core/providers/settings/app_paths/app_paths_provider.dart';
import 'package:clipshare/core/providers/settings/preference/preference_settings_provider.dart';
import 'package:clipshare/core/providers/settings/quick/quick_settings_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:window_manager/window_manager.dart';

part 'app_startup_provider.g.dart';

@riverpod
Future<void> appStartup(Ref ref) async {
  await Future.wait([
    ref.watch(appPathsProvider.future),
    ref.watch(localDeviceInfoProvider.future),
    ref.watch(quickSettingsProvider.future),
    ref.watch(preferenceSettingsProvider.future),
  ]);
  await _initWindowsManager(ref);
}

Future<void> _initWindowsManager(Ref ref) async {
  if (!isDesktop) {
    return;
  }
  var preferenceSettings = ref.watch(preferenceSettingsProvider).requireValue;
  final windowOptions = WindowOptions(
    size: preferenceSettings.windowSize,
    minimumSize: kReleaseMode ? const Size(showHistoryRightWidth * 1.0, 200) : null,
    center: true,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );
  var quickSettings = ref.watch(quickSettingsProvider).requireValue;
  await ref.read(windowControlProvider.notifier).syncWindowState();
  return windowManager.waitUntilReadyToShow(windowOptions, () async {
    if (!quickSettings.startMini) {
      //非最小化启动
      await windowManager.show();
      await windowManager.focus();
    }
  });
}