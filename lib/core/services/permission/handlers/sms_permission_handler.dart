import 'package:clipshare/core/services/rules/rules_provider.dart';
import 'package:flutter/material.dart';

import '../permission_helper.dart';
import 'abstract_permission_handler.dart';

/// 无障碍权限处理器
class SmsPermissionHandler extends AbstractPermissionHandler {
  final RulesExecutorNotifier _rulesExecutor;

  SmsPermissionHandler(this._rulesExecutor);

  @override
  Future<void> request(BuildContext context) async {
    await PermissionHelper.reqAndroidReadSms();
  }

  @override
  Future<bool> hasPermission() async {
    final granted = await PermissionHelper.testAndroidReadSms();
    //有权限或者不需要读取短信则视为有权限
    return granted || !_rulesExecutor.enableSmsSync;
  }
}
