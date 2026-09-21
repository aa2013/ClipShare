import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/models/dialog_actions.dart';
import 'package:clipshare/shared/utils/dialog.dart';
import 'package:flutter/material.dart';

/// 权限处理器基类。
///
/// 子类只负责「查询是否已授权」与「发起授权」两件事
/// 授权说明弹窗统一由 [showAuthorizeDialog] 弹出
abstract class AbstractPermissionHandler {
  /// 拉起授权流程；实现方按平台差异跳转系统设置页或直接触发系统授权弹窗。
  Future<void> request(BuildContext context);

  /// 查询权限是否已经授权。
  Future<bool> hasPermission();
}

/// 弹出授权说明弹窗，确认与取消按钮均先关闭本弹窗再执行回调。
///
/// [onCancel] 用于补充取消授权的后果提示；[cancelText] 可覆盖取消按钮文案
/// （例如已选择「不再提示」后改回普通取消）。
void showAuthorizeDialog({
  required BuildContext context,
  required String title,
  required String content,
  void Function(BuildContext context)? onCancel,
  required void Function(BuildContext context) onConfirm,
  String? cancelText,
  String? confirmText,
}) {
  dialogManager.tips(
    context,
    title: title,
    text: content,
    actions: DialogActions(
      cancel: DialogAction(
        text: cancelText ?? TranslationKey.dialogCancelText.tr,
        onPressed: () => onCancel?.call(context),
      ),
      confirm: DialogAction(
        text: confirmText ?? TranslationKey.dialogAuthorizationButtonText.tr,
        onPressed: () => onConfirm(context),
      ),
    ),
  );
}
