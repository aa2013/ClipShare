import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/constants/ui_constants.dart';
import 'package:clipshare/shared/extensions/context_extension.dart';
import 'package:clipshare/shared/models/dialog_actions.dart';
import 'package:clipshare/shared/widgets/base/dialog_actions_bar.dart';
import 'package:flutter/material.dart';

/// 通用弹窗边框布局，仅用于非小屏幕。
///
/// 统一提供图标/标题头部与右上角关闭按钮，正文区域由外部 [content] 填充；
/// 整体宽高可按需指定，未指定时按屏幕尺寸比例自适应并钳制在合理区间。
class DialogFrameLayout extends StatelessWidget {
  /// 头部图标，为空时不显示。
  final IconData? icon;

  /// 头部标题。
  final String title;

  /// 正文内容，由外部传入填充剩余区域。
  final Widget content;

  /// 弹窗宽度；为空时按屏幕宽度比例计算默认值。
  final double? width;

  /// 弹窗高度；为空时按屏幕高度比例计算默认值。
  final double? height;

  /// 右上角关闭回调；为空时回退为关闭当前路由。
  final VoidCallback? onClose;

  /// 是否显示右上角关闭按钮。
  final bool showCloseButton;

  /// 弹窗背景色；为空时取当前主题的表面色。
  final Color? backgroundColor;

  /// 底部通用区域；为空时不渲染。与 [actions] 可共存，位于 [actions] 上方。
  final Widget? footer;

  /// 底部按钮组，neutral 居左、cancel/confirm 居右；为空时不渲染。
  final DialogActions? actions;

  /// 正文是否由边框包裹滚动；传入 ListView 等自身可滚动组件时应设为 false。
  final bool scrollable;

  /// 底部按钮点击后是否自动关闭弹窗；为 false 时由按钮回调自行控制关闭时机。
  final bool autoDismiss;

  // 默认宽度占屏幕宽度的比例。
  static const double _defaultWidthRatio = 0.6;

  // 默认高度占屏幕高度的比例。
  static const double _defaultHeightRatio = 0.7;

  // 默认宽度区间，避免过窄或过宽。
  static const double _minWidth = 480;
  static const double _maxWidth = 720;

  // 默认高度区间，避免过矮或过高。
  static const double _minHeight = 420;
  static const double _maxHeight = 720;

  static const double _headerHeight = 48;
  static const double _headerIconSize = 20;
  static const EdgeInsetsGeometry _headerPadding = EdgeInsets.symmetric(horizontal: 16);
  static const EdgeInsetsGeometry _contentPadding = EdgeInsets.fromLTRB(16, 12, 16, 16);
  static const EdgeInsetsGeometry _footerPadding = EdgeInsets.fromLTRB(16, 8, 16, 12);
  static const double _footerGap = 8;

  const DialogFrameLayout({
    super.key,
    this.icon,
    required this.title,
    required this.content,
    this.width,
    this.height,
    this.onClose,
    this.showCloseButton = true,
    this.backgroundColor,
    this.footer,
    this.actions,
    this.scrollable = true,
    this.autoDismiss = true,
  });

  @override
  Widget build(BuildContext context) {
    assert(!context.isCompactScreen, 'DialogFrameLayout is only supported on non-compact screens');
    final theme = context.currentTheme;
    final size = context.media.size;
    final resolvedWidth = (width ?? size.width * _defaultWidthRatio).clamp(_minWidth, _maxWidth).toDouble();
    final resolvedHeight = (height ?? size.height * _defaultHeightRatio).clamp(_minHeight, _maxHeight).toDouble();
    final footerWidget = _buildFooter();
    // 弹窗路由会给出铺满全屏的紧约束，必须用 Center 松开约束，SizedBox 才能按尺寸生效。
    return Center(
      child: Material(
        color: backgroundColor ?? theme.dialogTheme.backgroundColor ?? theme.colorScheme.surface,
        elevation: 8,
        borderRadius: BorderRadius.circular(dialogCornerRadius),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: resolvedWidth,
          height: resolvedHeight,
          child: Column(
            children: [
              _buildHeader(context),
              _buildDivider(theme),
              Expanded(child: _buildBody()),
              if (footerWidget != null) ...[
                _buildDivider(theme),
                Padding(
                  padding: _footerPadding,
                  child: footerWidget,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 构建正文；[scrollable] 为 true 时由边框包裹滚动，保证 header/footer 始终可见。
  /// 强制铺满弹窗宽度，避免滚动视口按内容收缩导致滚动条停在中间。
  Widget _buildBody() {
    return SizedBox(
      width: double.infinity,
      child: scrollable
          ? SingleChildScrollView(
              padding: _contentPadding,
              child: content,
            )
          : Padding(
              padding: _contentPadding,
              child: content,
            ),
    );
  }

  /// 构建底部区域：footer 在上、actions 在下；两者都为空时返回 null 不渲染。
  Widget? _buildFooter() {
    final hasActions = actions != null && !actions!.isEmpty;
    if (footer == null && !hasActions) {
      return null;
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (footer != null) footer!,
        if (footer != null && hasActions) const SizedBox(height: _footerGap),
        if (hasActions)
          DialogActionsBar(
            actions: actions!,
            autoDismiss: autoDismiss,
            onClose: onClose,
          ),
      ],
    );
  }

  /// 构建分隔线，header 与 footer 共用同一样式。
  Widget _buildDivider(ThemeData theme) {
    return Divider(
      height: 1,
      thickness: 1,
      color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
    );
  }

  /// 构建头部：左侧图标 + 标题，右侧为可选的关闭按钮。
  Widget _buildHeader(BuildContext context) {
    final theme = context.currentTheme;
    return SizedBox(
      height: _headerHeight,
      child: Padding(
        padding: _headerPadding,
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: _headerIconSize,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (showCloseButton)
              IconButton(
                onPressed: onClose ?? () => Navigator.of(context).pop(),
                mouseCursor: SystemMouseCursors.click,
                tooltip: TranslationKey.close.tr,
                icon: const Icon(Icons.close, size: _headerIconSize),
              ),
          ],
        ),
      ),
    );
  }
}
