import 'package:clipshare/features/settings/enums/settings_section.dart';
import 'package:clipshare/features/settings/widgets/card/setting_entry.dart';
import 'package:flutter/material.dart';

abstract class SettingsSectionView extends StatelessWidget {
  final SettingsSection section;
  final bool embedded;
  static const tag = 'SettingsSectionView';

  const SettingsSectionView({
    super.key,
    required this.section,
    this.embedded = false,
  });


  final arrowForwardIcon = const Icon(
    Icons.arrow_forward_rounded,
    color: Colors.blueGrey,
  );

  // Each concrete page owns one first-level settings section.
  bool get showGroupHeader => false;

  List<SettingEntry> buildSettingEntries(BuildContext context) => const [];

  List<Widget> buildCards(BuildContext context);

  List<SettingsSearchItem> buildSearchItems(BuildContext context) {
    return buildSettingEntries(context)
        .where((entry) => entry.visible && (entry.searchKeys.isNotEmpty || entry.searchAliases.isNotEmpty))
        .map((entry) {
          return SettingsSearchItem(
            section: section,
            searchId: entry.searchId,
            searchKeys: entry.searchKeys,
            searchAliases: entry.searchAliases,
          );
        })
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: embedded ? const EdgeInsets.fromLTRB(18, 8, 18, 18) : const EdgeInsets.fromLTRB(8, 12, 8, 12),
      child: ListView(
        children: [
          ...buildCards(context),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
