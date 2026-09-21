import 'package:clipshare/core/platform/channels/android/android_channel_provider.dart';
import 'package:clipshare/core/services/permission/handlers/accessibility_permission_handler.dart';
import 'package:clipshare/core/services/permission/handlers/notification_record_permission_handler.dart';
import 'package:clipshare/core/services/permission/handlers/sms_permission_handler.dart';
import 'package:clipshare/core/services/permission/permission_info.dart';
import 'package:clipshare/core/services/rules/rules_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'handlers/clipboard_permission_handler.dart';
import 'handlers/float_permission_handler.dart';
import 'handlers/ignore_battery_permission_handler.dart';
import 'handlers/ios_photos_handler.dart';
import 'handlers/notify_permission_handler.dart';

part 'permission_info_provider.g.dart';

@Riverpod(keepAlive: true)
class PermissionInfoNotifier extends _$PermissionInfoNotifier with WidgetsBindingObserver {
  //通知权限
  late NotifyPermissionHandler _notifyHandler;

  //悬浮窗权限
  late FloatPermissionHandler _floatHandler;

  //检查短信权限
  late SmsPermissionHandler _smsHandler;

  //剪贴板权限
  final _clipboardHandler = ClipboardPermissionHandler();

  //检查电池优化
  final _ignoreBatteryHandler = IgnoreBatteryPermissionHandler();

  //检查无障碍相册权限
  final _accessibilityHandler = AccessibilityPermissionHandler();

  //检查通知记录权限
  final _notificationRecordHandler = NotificationRecordPermissionHandler();

  //检查IOS相册权限
  final _iosPhotosHandler = IosPhotosPermissionHandler();

  @override
  Future<PermissionInfo> build() async {
    final androidChannel = ref.read(androidChannelProvider.notifier);
    _notifyHandler = NotifyPermissionHandler(androidChannel);
    _floatHandler = FloatPermissionHandler(androidChannel);
    final rulesExecutor = ref.read(rulesExecutorProvider.notifier);
    _smsHandler = SmsPermissionHandler(rulesExecutor);
    WidgetsBinding.instance.addObserver(this);
    ref.onDispose(_onDispose);
    return await _updatePermissionInfo();
  }

  Future<PermissionInfo> _updatePermissionInfo() async {
    final hasNotifyPermission = await _notifyHandler.hasPermission();
    final hasNotificationRecordPermission = await _notificationRecordHandler.hasPermission();
    final hasFloatWindowPermission = await _floatHandler.hasPermission();
    final hasIgnoreBatteryPermission = await _ignoreBatteryHandler.hasPermission();
    final hasSmsReadPermission = await _smsHandler.hasPermission();
    final hasAccessibilityPermission = await _accessibilityHandler.hasPermission();
    final hasIOSPhotosPermission = await _iosPhotosHandler.hasPermission();
    final hasClipboardPermission = await _clipboardHandler.hasPermission();
    return PermissionInfo(
      hasNotifyPermission: hasNotifyPermission,
      hasNotificationRecordPermission: hasNotificationRecordPermission,
      hasFloatWindowPermission: hasFloatWindowPermission,
      hasIgnoreBatteryPermission: hasIgnoreBatteryPermission,
      hasSmsReadPermission: hasSmsReadPermission,
      hasAccessibilityPermission: hasAccessibilityPermission,
      hasIOSPhotosPermission: hasIOSPhotosPermission,
      hasClipboardPermission: hasClipboardPermission,
    );
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.resumed:
        this.state = AsyncData(await _updatePermissionInfo());
        break;
      default:
    }
  }

  void _onDispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  Future<void> requestNotificationPermission(BuildContext context) {
    return _notifyHandler.request(context);
  }

  Future<void> requestFloatWindowPermission(BuildContext context) {
    return _floatHandler.request(context);
  }

  Future<void> requestIgnoreBatteryPermission(BuildContext context) {
    return _ignoreBatteryHandler.request(context);
  }

  Future<void> requestAccessibilityPermission(BuildContext context) {
    return _accessibilityHandler.request(context);
  }

  Future<void> requestIosPhotosPermission(BuildContext context) {
    return _iosPhotosHandler.request(context);
  }
  Future<void> requestClipboardPermission(BuildContext context) {
    return _clipboardHandler.request(context);
  }
}
