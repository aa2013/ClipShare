import 'package:clipshare/features/guide/models/guide_step.dart';
import 'package:flutter/material.dart';

/// 引导步骤的通用版式：标题 + 图标 + 说明文案 + 底部操作。
///
/// 权限步骤、工作模式步骤与完成页共用该版式，新增步骤只需提供描述与底部操作。
class GuideStepScaffold extends StatelessWidget {
  /// 步骤描述，提供标题、说明与图标。
  final GuideStepSpec step;

  /// 底部操作区，例如授权按钮或跳转按钮；为空时不渲染。
  final Widget? footer;

  /// 标题与图标之间的间距。
  static const double _titleIconGap = 20;

  /// 图标与说明之间的间距。
  static const double _iconDescGap = 20;

  /// 说明与底部操作之间的间距。
  static const double _descFooterGap = 30;

  /// 说明文案的左右留白。
  static const double _descHorizontalPadding = 12;

  /// 步骤图标尺寸。
  static const double _iconSize = 60;

  const GuideStepScaffold({
    super.key,
    required this.step,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final icon = step.icon;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          step.titleText,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: _titleIconGap),
        if (icon != null)
          Icon(
            icon,
            size: _iconSize,
            color: Colors.blueAccent,
          ),
        const SizedBox(height: _iconDescGap),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: _descHorizontalPadding,
          ),
          child: Text(
            step.descriptionText,
            textAlign: TextAlign.center,
          ),
        ),
        if (footer != null) ...[
          const SizedBox(height: _descFooterGap),
          footer!,
        ],
      ],
    );
  }
}