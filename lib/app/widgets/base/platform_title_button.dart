import 'dart:io';

import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

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
    return _buildButton(
      isHovered: _isHovered,
      hoverColor: widget.hoverColor ?? Colors.grey[200]!,
      iconColor: widget.iconColor ?? Colors.grey[600]!,
      icon: widget.icon,
      onHover: (value) => setState(() => _isHovered = value),
      onTap: widget.onTap,
    );
  }

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
