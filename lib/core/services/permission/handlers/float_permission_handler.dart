import 'package:clipshare/core/platform/channels/android/android_channel_provider.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/utils/dialog.dart';
import 'package:flutter/material.dart';

import 'abstract_permission_handler.dart';

/// 悬浮窗权限处理请求。
///
/// Android 10 及以上系统不允许后台读取剪贴板，需要悬浮窗权限间接获取剪贴板焦点。
class FloatPermissionHandler extends AbstractPermissionHandler {
  final AndroidChannelNotifier _androidChannel;

  FloatPermissionHandler(this._androidChannel);

  @override
  Future<void> request(BuildContext context) async {
    showAuthorizeDialog(
      context: context,
      title: TranslationKey.floatPermRequestDialogTitle.tr,
      content: TranslationKey.floatPermRequestDialogContent.tr,
      onCancel: _showMissingTips,
      onConfirm: (ctx) async {
        await _androidChannel.grantAlertWindowPermission();
        // 授权结果由系统设置页返回后复查，仍缺失时提示该权限为必要权限。
        final granted = await hasPermission();
        if (granted || !ctx.mounted) {
          return;
        }
        await _showMissingTips(ctx);
      },
    );
  }

  @override
  Future<bool> hasPermission() {
    return _androidChannel.checkAlertWindowPermission();
  }

  /// 提示悬浮窗权限缺失会导致无法后台读取剪贴板。
  Future<void> _showMissingTips(BuildContext context) {
    return dialogManager.tips(
      context,
      title: TranslationKey.requiredPermDialogTitle.tr,
      text: TranslationKey.floatPermMissingDialogContent.tr,
    );
  }
}