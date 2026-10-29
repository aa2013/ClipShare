import 'package:clipshare/core/constants/platform_constants.dart';
import 'package:clipshare/core/platform/channels/android/android_channel_provider.dart';
import 'package:clipshare/core/services/permission/permission_helper.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:flutter/material.dart';

import 'abstract_permission_handler.dart';

/// 通知权限处理请求。
///
/// Android 侧由原生跳转系统通知设置页，授权结果通过 [AndroidChannelNotifier.checkNotification] 复查；
/// iOS 侧直接走系统授权弹窗。
class NotifyPermissionHandler extends AbstractPermissionHandler {
  final AndroidChannelNotifier _androidChannel;

  NotifyPermissionHandler(this._androidChannel);

  @override
  Future<void> request(BuildContext context) async {
    if (!isAndroid && !isIOS) return;
    if (isAndroid) {
      showAuthorizeDialog(
        context: context,
        title: TranslationKey.notificationPermRequestDialogTitle.tr,
        content: TranslationKey.notificationPermRequestDialogContent.tr,
        onConfirm: (_) => _androidChannel.grantNotification(),
      );
      return;
    }
    await PermissionHelper.reqIOSNotificationPermission();
  }

  @override
  Future<bool> hasPermission() async {
    if (!isAndroid && !isIOS) return false;
    if (isAndroid) {
      return _androidChannel.checkNotification();
    }
    return PermissionHelper.checkIOSNotificationPermission();
  }
}