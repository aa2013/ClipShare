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

  /// 生成按钮点击回调：autoDismiss 时先关闭弹窗，再执行按钮自身逻辑。
  VoidCallback _handlePress(BuildContext context, DialogAction action) {
    return () {
      if (autoDismiss) {
        (onClose ?? () => Navigator.of(context).pop())();
      }
      action.onPressed?.call();
    };
  }

  Widget _buildButton(BuildContext context, DialogAction action, String fallbackText) {
    final child = Text(action.text ?? fallbackText);
    final enabled = action.enabled;
    if (enabled == null) {
      return TextButton(
        onPressed: _handlePress(context, action),
        child: child,
      );
    }
    // 监听 enabled 动态控制按钮是否可点。
    return ValueListenableBuilder<bool>(
      valueListenable: enabled,
      builder: (context, isEnabled, _) {
        return TextButton(
          onPressed: isEnabled ? _handlePress(context, action) : null,
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }
    final confirm = actions.confirm;
    final cancel = actions.cancel;
    final neutral = actions.neutral;

    return Row(
      children: [
        if (neutral != null) _buildButton(context, neutral, TranslationKey.dialogNeutralText.tr),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (cancel != null) _buildButton(context, cancel, TranslationKey.dialogCancelText.tr),
              if (confirm != null) _buildButton(context, confirm, TranslationKey.dialogConfirmText.tr),
            ],
          ),
        ),
      ],
    );
  }
}