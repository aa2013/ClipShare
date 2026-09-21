import 'package:flutter/material.dart';

import '../permission_helper.dart';
import 'abstract_permission_handler.dart';

/// 无障碍权限处理器
class AccessibilityPermissionHandler extends AbstractPermissionHandler {

  @override
  Future<void> request(BuildContext context) async {
    await PermissionHelper.reqAndroidAccessibilityPerm();
  }

  @override
  Future<bool> hasPermission() async {
    return await PermissionHelper.testAndroidAccessibilityPerm();
  }
}
