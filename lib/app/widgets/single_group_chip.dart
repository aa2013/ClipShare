import 'package:flutter/material.dart';

class SingleGroupChip extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;
  static final _borderRadius = BorderRadius.circular(12.0);

  const SingleGroupChip({
    super.key,
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: _borderRadius,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary.withOpacity(0.15) : theme.dialogTheme.backgroundColor,
          borderRadius: _borderRadius,
          border: Border.all(
            color: isSelected ? colorScheme.primary : theme.dividerColor,
            width: 1.0,
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 10.0,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
              size: 16,
              color: isSelected ? colorScheme.primary : theme.disabledColor,
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isSelected ? colorScheme.primary : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
