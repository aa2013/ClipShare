import 'package:clipshare/core/services/permission/permission_handler_facade.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:flutter/material.dart';

import 'abstract_permission_handler.dart';

/// 电池优化权限处理请求。
///
/// 取消电池优化可提高后台存活率，用户也可直接在系统设置中手动调整。
class IgnoreBatteryPermissionHandler extends AbstractPermissionHandler {
  @override
  Future<void> request(BuildContext context) async {
    showAuthorizeDialog(
      context: context,
      title: TranslationKey.batteryOptimization.tr,
      content: TranslationKey.batteryOptimizationPermRequestDialogContent.tr,
      onConfirm: (_) => Permission.ignoreBatteryOptimizations.request(),
    );
  }

  @override
  Future<bool> hasPermission() async {
    return Permission.ignoreBatteryOptimizations.isGranted;
  }
}
