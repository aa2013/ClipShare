import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/models/dialog_actions.dart';
import 'package:flutter/material.dart';

/// 弹窗底部按钮条：neutral 居左，cancel/confirm 居右。
///
/// [autoDismiss] 为 true 时按钮点击后先触发 [onClose]（默认关闭当前路由），
/// 再执行按钮自身的 [DialogAction.onPressed]。
class DialogActionsBar extends StatelessWidget {
  /// 待展示的按钮组。
  final DialogActions actions;

  /// 点击按钮后是否自动关闭弹窗。
  final bool autoDismiss;

  /// 自动关闭时的关闭回调；为空时回退为关闭当前路由。
  final VoidCallback? onClose;

  const DialogActionsBar({
    super.key,
    required this.actions,
    this.autoDismiss = true,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }
    final confirm = actions.confirm;
    final cancel = actions.cancel;
    final neutral = actions.neutral;

    TextButton buildButton(DialogAction action, String fallbackText) {
      return TextButton(
        onPressed: () {
          if (autoDismiss) {
            (onClose ?? () => Navigator.of(context).pop())();
          }
          action.onPressed?.call();
        },
        child: Text(action.text ?? fallbackText),
      );
    }

    return Row(
      children: [
        if (neutral != null) buildButton(neutral, TranslationKey.dialogNeutralText.tr),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (cancel != null) buildButton(cancel, TranslationKey.dialogCancelText.tr),
              if (confirm != null) buildButton(confirm, TranslationKey.dialogConfirmText.tr),
            ],
          ),
        ),
      ],
    );
  }
}
