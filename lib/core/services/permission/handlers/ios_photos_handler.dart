import 'package:clipshare/core/constants/platform_constants.dart';
import 'package:clipshare/core/services/permission/permission_helper.dart';
import 'package:flutter/cupertino.dart';

import 'abstract_permission_handler.dart';

/// IOS 相册权限处理请求，用于读取与保存图片。
class IosPhotosPermissionHandler extends AbstractPermissionHandler {
  @override
  Future<bool> hasPermission() async {
    if (!isIOS) return false;
    return await PermissionHelper.checkIOSPhotoPermission();
  }

  @override
  Future<void> request(BuildContext context) async {
    if (!isIOS) return;
    await PermissionHelper.reqIOSPhotoPermission();
  }
}
