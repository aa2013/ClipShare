import 'package:clipshare/features/settings/enums/settings_section.dart';
import 'package:clipshare/features/settings/pages/level2/settings_about_page.dart';
import 'package:clipshare/features/settings/pages/level2/settings_backup_page.dart';
import 'package:clipshare/features/settings/pages/level2/settings_clipboard_page.dart';
import 'package:clipshare/features/settings/pages/level2/settings_data_cleanup_page.dart';
import 'package:clipshare/features/settings/pages/level2/settings_discovery_page.dart';
import 'package:clipshare/features/settings/pages/level2/settings_float_window_page.dart';
import 'package:clipshare/features/settings/pages/level2/settings_forward_page.dart';
import 'package:clipshare/features/settings/pages/level2/settings_hot_key_page.dart';
import 'package:clipshare/features/settings/pages/level2/settings_language_page.dart';
import 'package:clipshare/features/settings/pages/level2/settings_log_page.dart';
import 'package:clipshare/features/settings/pages/level2/settings_notification_page.dart';
import 'package:clipshare/features/settings/pages/level2/settings_permission_page.dart';
import 'package:clipshare/features/settings/pages/level2/settings_preference_page.dart';
import 'package:clipshare/features/settings/pages/level2/settings_security_page.dart';
import 'package:clipshare/features/settings/pages/level2/settings_statistics_page.dart';
import 'package:clipshare/features/settings/pages/level2/settings_sync_page.dart';
import 'package:clipshare/features/settings/pages/settings_section_view_base.dart';
import 'package:flutter/widgets.dart';

SettingsSectionView? buildSettingsSectionView(
  SettingsSection section, {
  bool embedded = false,
}) {
  switch (section) {
    case .language:
      return SettingsLanguagePage(embedded: embedded);
    case .preference:
      return SettingsPreferencePage(embedded: embedded);
    case .notification:
      return SettingsNotificationPage(embedded: embedded);
    case .clipboard:
      return SettingsClipboardPage(embedded: embedded);
    case .permission:
      return SettingsPermissionPage(embedded: embedded);
    case .floatWindow:
      return SettingsFloatWindowPage(embedded: embedded);
    case .discovery:
      return SettingsDiscoveryPage(embedded: embedded);
    case .forward:
      return SettingsForwardPage(embedded: embedded);
    case .security:
      return SettingsSecurityPage(embedded: embedded);
    case .hotKey:
      return SettingsHotKeyPage(embedded: embedded);
    case .sync:
      return SettingsSyncPage(embedded: embedded);
    case .dataCleanup:
      return SettingsDataCleanupPage(embedded: embedded);
    case .backup:
      return SettingsBackupPage(embedded: embedded);
    case .aboutLog:
      return SettingsAboutPage(embedded: embedded);
    case .log:
      return SettingsLogPage(embedded: embedded);
    default:
      return null;
  }
}

Widget buildSettingsSectionContent(
  SettingsSection section, {
  bool embedded = false,
}) {
  if (section == .statistics) {
    return SettingsStatisticsPage(embedded: embedded);
  }
  return buildSettingsSectionView(section, embedded: embedded) ?? const SizedBox.shrink();
}
