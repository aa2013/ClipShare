import 'dart:ui';

import 'package:flutter/material.dart';

class BlurBackground extends StatelessWidget {
  final Widget child; // 子组件
  final double blurSigma; // 模糊程度
  final Color? overlayColor; // 覆盖层颜色
  final BorderRadius? borderRadius; // 圆角

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
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma), // 模糊效果
        child: Container(
          decoration: BoxDecoration(
            color: overlayColor ?? Colors.white.withOpacity(0.1), // 覆盖层颜色
            borderRadius: borderRadius, // 圆角
          ),
          child: child, // 子组件
        ),
      ),
    );
  }
}
