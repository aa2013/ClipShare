
import 'package:clipshare/features/settings/enums/settings_section.dart';
import 'package:clipshare/features/settings/pages/settings_section_view_base.dart';
import 'package:flutter/widgets.dart';

SettingsSectionView? buildSettingsSectionView(
  SettingsSection section, {
  bool embedded = false,
}) {
  switch (section) {
    // case SettingsSection.language:
    //   return SettingsLanguagePage(embedded: embedded);
    // case SettingsSection.preference:
    //   return SettingsPreferencePage(embedded: embedded);
    // case SettingsSection.notification:
    //   return SettingsNotificationPage(embedded: embedded);
    // case SettingsSection.clipboard:
    //   return SettingsClipboardPage(embedded: embedded);
    // case SettingsSection.permission:
    //   return SettingsPermissionPage(embedded: embedded);
    // case SettingsSection.floatWindow:
    //   return SettingsFloatWindowPage(embedded: embedded);
    // case SettingsSection.connectivity:
    //   return SettingsConnectivityPage(embedded: embedded);
    // case SettingsSection.forward:
    //   return SettingsForwardPage(embedded: embedded);
    // case SettingsSection.security:
    //   return SettingsSecurityPage(embedded: embedded);
    // case SettingsSection.hotKey:
    //   return SettingsHotKeyPage(embedded: embedded);
    // case SettingsSection.sync:
    //   return SettingsSyncPage(embedded: embedded);
    // case SettingsSection.cleanData:
    //   return SettingsCleanDataPage(embedded: embedded);
    // case SettingsSection.rules:
    //   return null;
    // case SettingsSection.backup:
    //   return SettingsBackupPage(embedded: embedded);
    // case SettingsSection.aboutLog:
    //   return SettingsAboutPage(embedded: embedded);
    // case SettingsSection.log:
    //   return SettingsLogPage(embedded: embedded);
    case SettingsSection.statistics:
      return null;
    default:
      return null;
  }
}

Widget buildSettingsSectionContent(
  SettingsSection section, {
  bool embedded = false,
}) {
  //todo
  // if (section == SettingsSection.statistics) {
  //   return SettingsStatisticsPage(embedded: embedded);
  // }
  return buildSettingsSectionView(section, embedded: embedded) ?? const SizedBox.shrink();
}
