import 'package:clipshare/features/settings/enums/settings_section.dart';
import 'package:clipshare/features/settings/widgets/section/settings_section_icon.dart';
import 'package:flutter/material.dart';

class SettingsSearchResultTile extends StatelessWidget {
  final SettingsSearchItem item;
  final VoidCallback onTap;

  const SettingsSearchResultTile({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.cardTheme.color ?? theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(10),
      child: ListTile(
        onTap: onTap,
        leading: SettingsSectionIcon(section: item.section, size: 38),
        title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(item.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.chevron_right_rounded),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
