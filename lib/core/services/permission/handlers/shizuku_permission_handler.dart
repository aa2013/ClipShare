import 'package:clipshare/core/platform/channels/android/android_channel_provider.dart';
import 'package:clipshare/core/runtime/app_state/app_state.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/models/dialog_actions.dart';
import 'package:clipshare/shared/utils/dialog.dart';
import 'package:flutter/material.dart';

import 'abstract_permission_handler.dart';

/// Shizuku 权限处理请求。
///
/// 用户主动选择「不再提示」后记入运行时配置，后续权限缺失不再重复弹窗。
class ShizukuPermissionHandler extends AbstractPermissionHandler {
  final AndroidChannelNotifier _androidChannel;

  /// 读取当前运行时配置，用于判断用户是否已选择「不再提示」。
  final AppState Function() _readAppState;

  /// 记录「不再提示」的选择。
  final void Function(bool ignore) _setIgnoreShizuku;

  ShizukuPermissionHandler(
    this._androidChannel, {
    required AppState Function() readAppState,
    required void Function(bool ignore) setIgnoreShizuku,
  })  : _readAppState = readAppState,
        _setIgnoreShizuku = setIgnoreShizuku;

  @override
  Future<void> request(BuildContext context) async {
    final ignoreShizuku = _readAppState().ignoreShizuku;
    showAuthorizeDialog(
      context: context,
      title: TranslationKey.shizukuPermRequestDialogTitle.tr,
      content: TranslationKey.shizukuPermRequestDialogContent.tr,
      // 已选择「不再提示」后，取消按钮改为普通取消，不再追加二次确认。
      cancelText: ignoreShizuku ? TranslationKey.dialogCancelText.tr : TranslationKey.dontShowAgain.tr,
      onCancel: ignoreShizuku ? null : _confirmIgnoreShizuku,
      onConfirm: (ctx) => _androidChannel.grantShizukuPermission(ctx),
    );
  }

  @override
  Future<bool> hasPermission() async {
    return await _androidChannel.checkShizukuPermission() ?? false;
  }

  /// 确认后记录「不再提示 Shizuku 权限缺失」。
  Future<void> _confirmIgnoreShizuku(BuildContext context) {
    return dialogManager.tips(
      context,
      text: TranslationKey.dontShowAgainConfirm.tr,
      actions: DialogActions(
        cancel: const DialogAction(),
        confirm: DialogAction(onPressed: () => _setIgnoreShizuku(true)),
      ),
    );
  }
}