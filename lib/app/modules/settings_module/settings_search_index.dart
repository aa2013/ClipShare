import 'package:clipshare/app/modules/settings_module/settings_section.dart';
import 'package:clipshare/app/modules/settings_module/settings_section_view_factory.dart';
import 'package:flutter/material.dart';

List<SettingsSearchItem> buildSettingsSearchItems(BuildContext context) {
  final generatedItems = SettingsSection.values.expand((section) {
    final view = buildSettingsSectionView(section, embedded: true);
    return view?.buildSearchItems(context) ?? <SettingsSearchItem>[];
  }).toList();
  return [
    ...generatedItems,
  ];
}
