import 'package:clipshare/app/modules/settings_module/pages/settings_about_page.dart';
import 'package:clipshare/app/modules/settings_module/pages/settings_backup_page.dart';
import 'package:clipshare/app/modules/settings_module/pages/settings_clipboard_page.dart';
import 'package:clipshare/app/modules/settings_module/pages/settings_connectivity_page.dart';
import 'package:clipshare/app/modules/settings_module/pages/settings_float_window_page.dart';
import 'package:clipshare/app/modules/settings_module/pages/settings_forward_page.dart';
import 'package:clipshare/app/modules/settings_module/pages/settings_hot_key_page.dart';
import 'package:clipshare/app/modules/settings_module/pages/settings_language_page.dart';
import 'package:clipshare/app/modules/settings_module/pages/settings_log_page.dart';
import 'package:clipshare/app/modules/settings_module/pages/settings_notification_page.dart';
import 'package:clipshare/app/modules/settings_module/pages/settings_permission_page.dart';
import 'package:clipshare/app/modules/settings_module/pages/settings_preference_page.dart';
import 'package:clipshare/app/modules/settings_module/pages/settings_section_view_base.dart';
import 'package:clipshare/app/modules/settings_module/pages/settings_security_page.dart';
import 'package:clipshare/app/modules/settings_module/pages/settings_statistics_page.dart';
import 'package:clipshare/app/modules/settings_module/pages/settings_sync_page.dart';

SettingsSectionView? buildSettingsSectionView(
  SettingsSection section, {
  bool embedded = false,
}) {
  switch (section) {
    case SettingsSection.language:
      return SettingsLanguagePage(embedded: embedded);
    case SettingsSection.preference:
      return SettingsPreferencePage(embedded: embedded);
    case SettingsSection.notification:
      return SettingsNotificationPage(embedded: embedded);
    case SettingsSection.clipboard:
      return SettingsClipboardPage(embedded: embedded);
    case SettingsSection.permission:
      return SettingsPermissionPage(embedded: embedded);
    case SettingsSection.floatWindow:
      return SettingsFloatWindowPage(embedded: embedded);
    case SettingsSection.connectivity:
      return SettingsConnectivityPage(embedded: embedded);
    case SettingsSection.forward:
      return SettingsForwardPage(embedded: embedded);
    case SettingsSection.security:
      return SettingsSecurityPage(embedded: embedded);
    case SettingsSection.hotKey:
      return SettingsHotKeyPage(embedded: embedded);
    case SettingsSection.sync:
      return SettingsSyncPage(embedded: embedded);
    case SettingsSection.rules:
      return null;
    case SettingsSection.backup:
      return SettingsBackupPage(embedded: embedded);
    case SettingsSection.aboutLog:
      return SettingsAboutPage(embedded: embedded);
    case SettingsSection.log:
      return SettingsLogPage(embedded: embedded);
    case SettingsSection.statistics:
      return null;
  }
}

Widget buildSettingsSectionContent(
  SettingsSection section, {
  bool embedded = false,
}) {
  if (section == SettingsSection.statistics) {
    return SettingsStatisticsPage(embedded: embedded);
  }
  return buildSettingsSectionView(section, embedded: embedded) ?? const SizedBox.shrink();
}
