import 'package:clipshare/core/extensions/context_extension.dart';
import 'package:clipshare/features/settings/enums/settings_section.dart';
import 'package:clipshare/features/settings/pages/settings_overview.dart';
import 'package:clipshare/features/settings/pages/settings_section_content.dart';
import 'package:flutter/widgets.dart';

class SettingsTabletPage extends StatefulWidget {
  const SettingsTabletPage({super.key});

  @override
  State<SettingsTabletPage> createState() => _SettingsTabletPageState();
}

class _SettingsTabletPageState extends State<SettingsTabletPage> {
  SettingsSection _selectedSection = SettingsSection.preference;
  String? _highlightedSearchId;

  @override
  Widget build(BuildContext context) {
    // Some promoted sections are hidden from the left list but still own a detail page.
    if (!isSettingsSectionAvailable(
      _selectedSection,
      context.isCompactScreen,
    )) {
      _selectedSection = SettingsSection.values.firstWhere(
        (section) =>
            isSettingsSectionListVisible(section, context.isCompactScreen),
      );
    }
    return Row(
      children: [
        SizedBox(
          width: 320,
          child: SettingsOverviewPage(
            embedded: true,
            selectedSection: _selectedSection,
            onSectionTap: (section) {
              setState(() {
                _selectedSection = section;
                _highlightedSearchId = null;
              });
            },
            onSearchItemTap: (item) {
              setState(() {
                _selectedSection = item.section;
                _highlightedSearchId = item.searchId.isEmpty
                    ? null
                    : item.searchId;
              });
            },
          ),
        ),
        Expanded(
          child: SettingsSectionContentPage(
            section: _selectedSection,
            embedded: true,
            highlightedSearchId: _highlightedSearchId,
          ),
        ),
      ],
    );
  }
}
