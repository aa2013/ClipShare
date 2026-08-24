import 'dart:io';

import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart';

export 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart'
    show Permission, PermissionStatus, PermissionStatusGetters;

PermissionHandlerPlatform get _permissionHandler =>
    PermissionHandlerPlatform.instance;

/// 打开当前应用的系统设置页；桌面端未接入权限插件时直接返回失败，避免误触发平台通道。
Future<bool> openAppSettings() {
  if (!Platform.isAndroid && !Platform.isIOS) {
    return Future.value(false);
  }
  return _permissionHandler.openAppSettings();
}

/// 复用 permission_handler 平台接口，补齐主包轻量调用形式。
extension PermissionFacadeActions on Permission {
  /// 查询单个权限状态；非移动端没有权限插件实现，统一按未授权处理。
  Future<PermissionStatus> get status {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return Future.value(PermissionStatus.denied);
    }
    return _permissionHandler.checkPermissionStatus(this);
  }

  /// 请求单个权限，并保持与 permission_handler 主包一致的返回语义。
  Future<PermissionStatus> request() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return PermissionStatus.denied;
    }
    final statuses = await _permissionHandler.requestPermissions([this]);
    return statuses[this] ?? PermissionStatus.denied;
  }

  /// 判断权限是否已经授权，保留现有业务代码的简洁读取方式。
  Future<bool> get isGranted async => (await status).isGranted;
}
