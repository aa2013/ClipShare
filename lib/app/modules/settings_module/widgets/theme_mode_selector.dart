import 'package:clipshare/app/utils/extensions/translation_key_extension.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ThemeModeSelector extends StatelessWidget {
  final ThemeMode value;
  final ValueChanged<ThemeMode> onChanged;

  const ThemeModeSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: ThemeMode.values.map((mode) {
        return _ThemeModeButton(
          mode: mode,
          selected: value == mode,
          onTap: () => onChanged(mode),
        );
      }).toList(),
    );
  }
}

class _ThemeModeButton extends StatelessWidget {
  final ThemeMode mode;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeModeButton({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedBg = theme.colorScheme.primary.withValues(alpha: Get.isDarkMode ? 0.22 : 0.12);
    final borderColor = selected ? theme.colorScheme.primary.withValues(alpha: Get.isDarkMode ? 0.62 : 0.36) : theme.colorScheme.onSurface.withValues(alpha: 0.10);
    final iconColor = selected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.62);
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Tooltip(
        message: mode.tk.name.tr,
        child: Material(
          color: selected ? selectedBg : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: borderColor),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            mouseCursor: SystemMouseCursors.click,
            onTap: onTap,
            child: SizedBox(
              width: 34,
              height: 34,
              child: Icon(
                _iconFor(mode),
                size: 18,
                color: iconColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconFor(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode_outlined;
      case ThemeMode.dark:
        return Icons.dark_mode_outlined;
      case ThemeMode.system:
        return Icons.brightness_auto_outlined;
    }
  }
}
