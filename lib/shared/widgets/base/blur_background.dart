import 'dart:ui';

import 'package:flutter/material.dart';

/// 高斯模糊背景遮罩。
///
/// 通过 [BackdropFilter] 对下层已绘制内容做模糊，叠加一层半透明覆盖色，
/// 常用于在页面之上叠加浮层时保留并虚化前一个页面的背景。
class BlurBackground extends StatelessWidget {
  /// 被模糊背景承载的子组件。
  final Widget child;

  /// 模糊程度，值越大越模糊。
  final double blurSigma;

  /// 覆盖层颜色，默认半透明白。
  final Color? overlayColor;

  /// 覆盖层圆角。
  final BorderRadius? borderRadius;

  const BlurBackground({
    super.key,
    required this.child,
    this.blurSigma = 10.0,
    this.overlayColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          decoration: BoxDecoration(
            color: overlayColor ?? Colors.white.withValues(alpha: 0.1),
            borderRadius: borderRadius,
          ),
          child: child,
        ),
      ),
    );
  }
}
