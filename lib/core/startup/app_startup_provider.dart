import 'dart:ui';

import 'package:clipshare/core/constants/app_constants.dart';
import 'package:clipshare/core/constants/platform_constants.dart';
import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/platform/android/screenshot_detect_provider.dart';
import 'package:clipshare/core/platform/channels/android/android_channel_provider.dart';
import 'package:clipshare/core/platform/channels/clip/clip_channel_provider.dart';
import 'package:clipshare/core/platform/channels/multi_window/multi_window_channel_provider.dart';
import 'package:clipshare/core/platform/desktop/hotkey/hot_key_provider.dart';
import 'package:clipshare/core/platform/desktop/tray/tray_provider.dart';
import 'package:clipshare/core/platform/desktop/window/window_control_provider.dart';
import 'package:clipshare/core/platform/desktop/window/window_provider.dart';
import 'package:clipshare/core/runtime/app_state/app_state_provider.dart';
import 'package:clipshare/core/runtime/network/network_change_coordinator_provider.dart';
import 'package:clipshare/core/services/clipboard/app_info_sync_provider.dart';
import 'package:clipshare/core/services/clipboard/clipboard_service_provider.dart';
import 'package:clipshare/core/services/clipboard/clipboard_source_provider.dart';
import 'package:clipshare/core/services/device/device_connection_notify_provider.dart';
import 'package:clipshare/core/services/device/device_provider.dart';
import 'package:clipshare/core/services/device/device_sync_provider.dart';
import 'package:clipshare/core/services/device/local_device_info_provider.dart';
import 'package:clipshare/core/services/history/data_cleanup_provider.dart';
import 'package:clipshare/core/services/history/history_recorder_provider.dart';
import 'package:clipshare/core/services/history/history_sync_provider.dart';
import 'package:clipshare/core/services/history/missing_data_sync_progress_provider.dart';
import 'package:clipshare/core/services/history/sync_auto_copy_provider.dart';
import 'package:clipshare/core/services/notify/notify_provider.dart';
import 'package:clipshare/core/services/permission/permission_info_provider.dart';
import 'package:clipshare/core/services/rules/rule_sync_provider.dart';
import 'package:clipshare/core/services/rules/rules_provider.dart';
import 'package:clipshare/core/services/rules/script_module_sync_provider.dart';
import 'package:clipshare/core/services/tag/tag_provider.dart';
import 'package:clipshare/core/services/tag/tag_sync_provider.dart';
import 'package:clipshare/core/services/transport/message_sync/ack_sync_consumer_provider.dart';
import 'package:clipshare/core/services/transport/message_sync/message_sync_provider.dart';
import 'package:clipshare/core/services/transport/message_sync/sync_receive_dispatcher_provider.dart';
import 'package:clipshare/core/services/transport/socket/direct/direct_provider.dart';
import 'package:clipshare/core/services/transport/socket/discovery/discovery_provider.dart';
import 'package:clipshare/core/services/transport/socket/forward/forward_server_provider.dart';
import 'package:clipshare/core/services/transport/socket/session/reconnect_provider.dart';
import 'package:clipshare/core/services/transport/socket/session/session_provider.dart';
import 'package:clipshare/core/services/transport/storage/storage_provider.dart';
import 'package:clipshare/core/settings/app_paths/app_paths_provider.dart';
import 'package:clipshare/core/settings/app_update/app_update_settings_provider.dart';
import 'package:clipshare/core/settings/clipboard/clipboard_settings_provider.dart';
import 'package:clipshare/core/settings/data_cleanup/data_cleanup_config_provider.dart';
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
    //日志开关配置尽早加载，使后续初始化阶段的日志可按开关落盘
    logSettingsProvider.future,
    notifyProvider.future,
    //region settings
    deviceSettingsProvider.future,
    localDeviceInfoProvider.future,
    quickSettingsProvider.future,
    preferenceSettingsProvider.future,
    dataCleanupConfigProvider.future,
    syncSettingsProvider.future,
    appUpdateSettingsProvider.future,
    securitySettingsProvider.future,
    discoverySettingsProvider.future,
    floatWindowSettingsProvider.future,
    notificationSettingsProvider.future,
    clipboardSettingsProvider.future,
    hotkeySettingsProvider.future,
    forwardSettingsProvider.future,
    //endregion
    tagProvider.future,
    deviceProvider.future,
    clipboardSourceProvider.future,
    rulesExecutorProvider.future,
    clipboardProvider.future,
    historyRecorderProvider.future,
    permissionInfoProvider.future,
  ];
  //不要使用 Future.wait() 因为顺序不保证可能导致后续初始化失败
  for (var provider in preloadFutures) {
    await ref.read(provider);
  }

  // 数据同步接收先于传输服务订阅，避免启动期消息在无监听者时被丢弃
  ref.read(messageSyncProvider);
  ref.read(syncReceiveDispatcherProvider);
  ref.read(ackSyncConsumerProvider);
  ref.read(historySyncProvider);
  ref.read(tagSyncProvider);
  ref.read(deviceSyncProvider);
  ref.read(appInfoSyncProvider);
  ref.read(ruleSyncProvider);
  ref.read(scriptModuleSyncProvider);

  // 数据清理服务
  ref.read(dataCleanupProvider);

  //自动复制与同步进度服务
  ref.read(syncAutoCopyProvider);
  ref.read(missingDataSyncProgressProvider);

  //设备连接通知服务，需在传输服务前订阅生命周期事件
  ref.read(deviceConnectionNotifyProvider);

  //传输服务相关
  ref.read(directProvider);
  ref.read(sessionProvider);
  ref.read(reconnectProvider);
  ref.read(forwardServerProvider);
  ref.read(discoveryProvider);
  ref.read(storageProvider);
  ref.read(networkChangeCoordinatorProvider);

  if (isDesktop) {
    // 窗口服务管理，需先于托盘初始化
    await ref.read(windowProvider.future);
    // 热键服务，注册热键需先于托盘
    await ref.read(hotKeyProvider.future);
    // 托盘服务
    await ref.read(trayProvider.future);
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
  final windowControl = ref.read(windowControlProvider.notifier);
  await windowControl.syncWindowState();
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
  final logSettings = await ref.read(logSettingsProvider.future);
  await channel.setAutoReportCrashes(logSettings.enableAutoUploadCrashLogs);
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
  //截图自动复制监听，是否实际开启由同步设置 autoCopyImageAfterScreenShot 控制
  final screenshotDetector = ref.read(screenshotDetectProvider.notifier);
  screenshotDetector.startListenScreenshot();
}
