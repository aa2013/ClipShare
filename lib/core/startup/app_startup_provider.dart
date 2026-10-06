import 'dart:ui';

import 'package:clipshare/core/constants/app_constants.dart';
import 'package:clipshare/core/constants/platform_constants.dart';
import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/platform/channels/android/android_channel_provider.dart';
import 'package:clipshare/core/platform/channels/clip/clip_channel_provider.dart';
import 'package:clipshare/core/platform/channels/multi_window/multi_window_channel_provider.dart';
import 'package:clipshare/core/platform/desktop/tray/tray_service_provider.dart';
import 'package:clipshare/core/platform/desktop/window/window_control_provider.dart';
import 'package:clipshare/core/platform/desktop/window/window_service_provider.dart';
import 'package:clipshare/core/runtime/app_state/app_state_provider.dart';
import 'package:clipshare/core/services/clipboard/clipboard_service_provider.dart';
import 'package:clipshare/core/services/clipboard/clipboard_source_provider.dart';
import 'package:clipshare/core/services/device/device_provider.dart';
import 'package:clipshare/core/services/device/local_device_info_provider.dart';
import 'package:clipshare/core/services/history/history_recorder_provider.dart';
import 'package:clipshare/core/services/notify/notify_provider.dart';
import 'package:clipshare/core/services/permission/permission_info_provider.dart';
import 'package:clipshare/core/services/rules/rules_provider.dart';
import 'package:clipshare/core/services/tag/tag_provider.dart';
import 'package:clipshare/core/services/transport/socket_provider.dart';
import 'package:clipshare/core/services/transport/storage_provider.dart';
import 'package:clipshare/core/settings/app_paths/app_paths_provider.dart';
import 'package:clipshare/core/settings/app_update/app_update_settings_provider.dart';
import 'package:clipshare/core/settings/clean/clean_data_config_provider.dart';
import 'package:clipshare/core/settings/clipboard/clipboard_settings_provider.dart';
import 'package:clipshare/core/settings/device/device_settings_provider.dart';
import 'package:clipshare/core/settings/discovery/discovery_settings_provider.dart';
import 'package:clipshare/core/settings/float/float_window_settings_provider.dart';
import 'package:clipshare/core/settings/forward/forward_settings_provider.dart';
import 'package:clipshare/core/settings/hotkey/hotkey_settings_provider.dart';
import 'package:clipshare/core/settings/log/log_settings_provider.dart';
import 'package:clipshare/core/settings/notification/notification_settings_provider.dart';
import 'package:clipshare/core/settings/preference/preference_settings_provider.dart';
import 'package:clipshare/core/settings/quick/quick_settings_provider.dart';
import 'package:clipshare/core/settings/security/security_settings_provider.dart';
import 'package:clipshare/core/settings/sync/sync_settings_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:window_manager/window_manager.dart';

part 'app_startup_provider.g.dart';

@riverpod
Future<void> appStartup(Ref ref) async {
  final appStateNotifier = ref.read(appStateProvider.notifier);
  //Riverpod 禁止一个 Provider 在其“构建期间”修改另一个 Provider 的状态。
  //此处增加 delayed 延迟到下一个任务执行
  await Future.delayed(Duration.zero, () {
    appStateNotifier.updateInitStatus(.initializing);
  });
  // 初始化平台通道
  _initChannels(ref);

  final List<Refreshable<Future>> preloadFutures = [
    appPathsProvider.future,
    appDbProvider.future,
    notifyProvider.future,
    //region settings
    deviceSettingsProvider.future,
    localDeviceInfoProvider.future,
    quickSettingsProvider.future,
    preferenceSettingsProvider.future,
    cleanDataConfigProvider.future,
    syncSettingsProvider.future,
    appUpdateSettingsProvider.future,
    securitySettingsProvider.future,
    discoverySettingsProvider.future,
    floatWindowSettingsProvider.future,
    notificationSettingsProvider.future,
    logSettingsProvider.future,
    clipboardSettingsProvider.future,
    hotkeySettingsProvider.future,
    forwardSettingsProvider.future,
    //endregion
    tagProvider.future,
    deviceProvider.future,
    clipboardSourceProvider.future,
    rulesExecutorProvider.future,
    clipboardServiceProvider.future,
    historyRecorderProvider.future,
    permissionInfoProvider.future,
  ];
  //不要使用 Future.wait() 因为顺序不保证可能导致后续初始化失败
  for (var provider in preloadFutures) {
    await ref.read(provider);
  }

  ref.read(socketProvider);
  ref.read(storageProvider);

  if (isDesktop) {
    // 窗口服务管理，需先于托盘初始化
    ref.read(windowServiceProvider);
    // 托盘服务
    ref.read(trayServiceProvider);
    // 窗口管理
    await _initWindowsManager(ref);
  }
  if (isAndroid) {
    await _initAndroid(ref);
  }
  // 启动预加载全部完成，标记为已初始化
  appStateNotifier.updateInitStatus(.initialized);
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

void _initChannels(Ref ref) {
  ref.read(clipChannelProvider);
  if (isAndroid) {
    ref.read(androidChannelProvider);
  }
  if (isDesktop) {
    ref.read(multiWindowChannelProvider);
  }
}

Future<void> _initAndroid(Ref ref) async {
  final channel = ref.read(androidChannelProvider.notifier);
  final floatSettings = await ref.read(floatWindowSettingsProvider.future);
  //todo
  // await channel.setAutoReportCrashes(appConfig.enableAutoUploadCrashLogs);
  if (floatSettings.showHistoryFloat) {
    await channel.showHistoryFloatWindow();
    if (floatSettings.lockHistoryFloatLoc) {
      await channel.lockHistoryFloatLoc(
        floatSettings.lockHistoryFloatLoc,
      );
    }
  }
  if (floatSettings.enhanceBackgroundKeepAlive) {
    await channel.showKeepAliveFloatWindow();
  }
}
