import 'package:clipshare/core/extensions/context_extension.dart';
import 'package:clipshare/features/settings/enums/settings_section.dart';
import 'package:clipshare/features/settings/pages/settings_overview.dart';
import 'package:clipshare/features/settings/pages/settings_tablet.dart';
import 'package:flutter/widgets.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (context.isCompactScreen) {
      return SettingsOverviewPage(
        onSectionTap: (section) => _openSection(section),
        onSearchItemTap: _openSearchItem,
      );
    }
    return const SettingsTabletPage();
  }

  void _openSection(SettingsSection section, {String? highlightedSearchId}) {
    if (!section.opensSecondaryPage) {
      //todo
      // Get.toNamed(Routes.RULES);
      return;
    }
    //todo
    // Get.to(
    //   () => SettingsSectionContentPage(
    //     section: section,
    //     highlightedSearchId: highlightedSearchId,
    //   ),
    // );
  }

  void _openSearchItem(SettingsSearchItem item) {
    _openSection(
      item.section,
      highlightedSearchId: item.searchId.isEmpty ? null : item.searchId,
    );
  }
}
