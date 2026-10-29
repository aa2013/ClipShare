import 'package:clipshare/core/services/permission/permission_helper.dart';
import 'package:flutter/material.dart';

import 'abstract_permission_handler.dart';

/// Android 存储权限处理请求。
///
/// 判定不只看权限声明，还要求目标目录真实可写，避免系统在分区存储下返回「已授权」
/// 但实际写入仍失败。
class AndroidStoragePermissionHandler extends AbstractPermissionHandler {
  final String _rootStorePath;
  final double _osVersion;

  AndroidStoragePermissionHandler(this._rootStorePath, this._osVersion);

  @override
  Future<void> request(BuildContext context) async {
    await PermissionHelper.reqAndroidStoragePerm(_rootStorePath, _osVersion);
  }

  @override
  Future<bool> hasPermission() async {
    return PermissionHelper.testAndroidStoragePerm(_rootStorePath, _osVersion);
  }
}