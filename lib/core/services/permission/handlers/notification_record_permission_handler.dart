import 'package:flutter/material.dart';
import 'package:notification_listener_service/notification_listener_service.dart';

import 'abstract_permission_handler.dart';

/// 通知记录权限处理器
class NotificationRecordPermissionHandler extends AbstractPermissionHandler {

  @override
  Future<void> request(BuildContext context) async {
    await NotificationListenerService.requestPermission();
  }

  @override
  Future<bool> hasPermission() async {
    return await NotificationListenerService.isPermissionGranted();
  }
}
