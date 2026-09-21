import 'dart:io';

import 'package:flutter/material.dart';

class PlatformTitleButton extends StatefulWidget {
  final VoidCallback? onTap;
  final Color? hoverColor;
  final Color? iconColor;
  final Color? hoveredIconColor;
  final double size;
  final IconData icon;

  const PlatformTitleButton({
    super.key,
    required this.size,
    required this.icon,
    this.onTap,
    this.hoverColor,
    this.iconColor,
    this.hoveredIconColor,
  });

  @override
  State<StatefulWidget> createState() => _PlatformTitleButtonState();
}

class _PlatformTitleButtonState extends State<PlatformTitleButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _buildButton(
      isHovered: _isHovered,
      hoverColor: widget.hoverColor ?? _resolveDefaultHoverColor(theme),
      iconColor: widget.iconColor ?? _resolveDefaultIconColor(theme),
      icon: widget.icon,
      onHover: (value) => setState(() => _isHovered = value),
      onTap: widget.onTap,
    );
  }

  /// 根据当前主题解析标题栏按钮的默认悬浮色，避免深色标题栏出现突兀的浅色块。
  Color _resolveDefaultHoverColor(ThemeData theme) {
    if (theme.brightness == Brightness.dark) {
      return theme.colorScheme.onSurface.withValues(alpha: 0.10);
    }
    return Colors.grey[200]!;
  }

  /// 根据当前主题解析标题栏按钮的默认图标色，保证自定义标题栏在明暗主题下都有足够对比度。
  Color _resolveDefaultIconColor(ThemeData theme) {
    return theme.appBarTheme.foregroundColor ?? theme.iconTheme.color ?? theme.colorScheme.onSurface;
  }

  /// 构建平台标题栏按钮，Linux 使用圆形悬浮区域以贴近系统窗口按钮样式。
  Widget _buildButton({
    required bool isHovered,
    required Color hoverColor,
    required Color iconColor,
    required IconData icon,
    required Function(bool) onHover,
    required VoidCallback? onTap,
  }) {
    return MouseRegion(
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: InkWell(
          hoverColor: hoverColor,
          customBorder: Platform.isLinux ? const CircleBorder() : null,
          mouseCursor: SystemMouseCursors.basic,
          onTap: onTap,
          child: Icon(
            icon,
            size: 14,
            color: isHovered && widget.hoveredIconColor != null ? widget.hoveredIconColor : iconColor,
          ),
        ),
      ),
    );
  }
}
