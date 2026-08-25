import 'package:clipshare/core/extensions/context_extension.dart';
import 'package:clipshare/features/settings/enums/settings_section.dart';
import 'package:flutter/material.dart';

class SettingsSectionIcon extends StatelessWidget {
  final SettingsSection section;
  final double size;

  const SettingsSectionIcon({
    super.key,
    required this.section,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    const accentColor = Colors.blueGrey;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: context.isDarkMode ? 0.20 : 0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(section.icon, color: accentColor, size: size * 0.52),
    );
  }
}

Color selectedSettingsTileColor(BuildContext context, Color baseColor) {
  final alpha = context.isDarkMode ? 0.24 : 0.16;
  return Color.alphaBlend(Colors.blueGrey.withValues(alpha: alpha), baseColor);
}
