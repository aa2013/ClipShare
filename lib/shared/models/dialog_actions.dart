import 'package:flutter/foundation.dart';

/// 单个弹窗按钮配置。
class DialogAction {
  final String? text;
  final VoidCallback? onPressed;

  /// 为空时按钮始终可用；否则实时监听该值控制按钮置灰。
  final ValueListenable<bool>? enabled;

  const DialogAction({
    this.text,
    this.onPressed,
    this.enabled,
  });
}

/// 弹窗底部按钮组：confirm/cancel 位于右侧，neutral 位于左侧。
///
/// 槽位传了才显示，未显式传 confirm 时默认提供一个"确定"按钮。
class DialogActions {
  final DialogAction? confirm;
  final DialogAction? cancel;
  final DialogAction? neutral;

  const DialogActions({
    this.confirm = const DialogAction(),
    this.cancel,
    this.neutral,
  });

  /// 三个槽位都未配置时表示不展示任何按钮。
  bool get isEmpty => confirm == null && cancel == null && neutral == null;
}
