import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:flutter/material.dart';

class SettingsEmptySearchTile extends StatelessWidget {
  const SettingsEmptySearchTile({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        TranslationKey.emptyData.tr,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.56)),
      ),
    );
  }
}
