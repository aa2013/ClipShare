import 'package:clipshare/core/constants/platform_constants.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:flutter/material.dart';

enum SettingsSection {
  language(
    titleKey: TranslationKey.language,
    subtitleKey: TranslationKey.settingsSectionLanguageSubtitle,
    icon: Icons.language_rounded,
  ),
  preference(
    titleKey: TranslationKey.preference,
    subtitleKey: TranslationKey.settingsSectionPreferenceSubtitle,
    icon: Icons.tune,
  ),
  notification(
    titleKey: TranslationKey.notification,
    subtitleKey: TranslationKey.settingsSectionNotificationSubtitle,
    icon: Icons.notifications_active_outlined,
  ),
  clipboard(
    titleKey: TranslationKey.clipboardSettingsGroupName,
    subtitleKey: TranslationKey.settingsSectionClipboardSubtitle,
    icon: Icons.content_paste_search_rounded,
  ),
  permission(
    titleKey: TranslationKey.permissionSettingsGroupName,
    subtitleKey: TranslationKey.settingsSectionPermissionSubtitle,
    icon: Icons.admin_panel_settings_outlined,
  ),
  floatWindow(
    titleKey: TranslationKey.floatWindow,
    subtitleKey: TranslationKey.settingsSectionFloatWindowSubtitle,
    icon: Icons.picture_in_picture_alt_rounded,
  ),
  connectivity(
    titleKey: TranslationKey.discoveringSettingsGroupName,
    subtitleKey: TranslationKey.settingsSectionDiscoverySubtitle,
    icon: Icons.hub_rounded,
  ),
  forward(
    titleKey: TranslationKey.forwardSettingsGroupName,
    subtitleKey: TranslationKey.settingsSectionForwardSubtitle,
    icon: Icons.cloud_sync_outlined,
  ),
  security(
    titleKey: TranslationKey.securitySettingsGroupName,
    subtitleKey: TranslationKey.settingsSectionSecuritySubtitle,
    icon: Icons.security_rounded,
  ),
  hotKey(
    titleKey: TranslationKey.hotKeySettingsGroupName,
    subtitleKey: TranslationKey.settingsSectionHotKeySubtitle,
    icon: Icons.keyboard_alt_outlined,
  ),
  sync(
    titleKey: TranslationKey.syncSettingsGroupName,
    subtitleKey: TranslationKey.settingsSectionSyncSubtitle,
    icon: Icons.sync_rounded,
  ),
  // 清理数据独立成设置分区，顺序位于同步与备份恢复之间。
  cleanData(
    titleKey: TranslationKey.cleanData,
    subtitleKey: TranslationKey.settingsSectionCleanDataSubtitle,
    icon: Icons.cleaning_services_outlined,
  ),
  rules(
    titleKey: TranslationKey.rulesManagement,
    subtitleKey: TranslationKey.settingsSectionRulesSubtitle,
    icon: Icons.rule_folder_outlined,
    opensSecondaryPage: false,
  ),
  backup(
    titleKey: TranslationKey.backupRestore,
    subtitleKey: TranslationKey.settingsSectionBackupSubtitle,
    icon: Icons.settings_backup_restore_rounded,
  ),
  statistics(
    titleKey: TranslationKey.statisticsSettingsGroupName,
    subtitleKey: TranslationKey.settingsSectionStatisticsSubtitle,
    icon: Icons.bar_chart_rounded,
  ),
  log(
    titleKey: TranslationKey.logSettingsGroupName,
    icon: Icons.bug_report_outlined,
  ),
  aboutLog(
    titleKey: TranslationKey.about,
    subtitleKey: TranslationKey.settingsSectionAboutLogSubtitle,
    icon: Icons.info_outline,
  );

  final TranslationKey titleKey;
  final TranslationKey? subtitleKey;
  final IconData icon;
  final bool opensSecondaryPage;

  const SettingsSection({
    required this.titleKey,
    this.subtitleKey,
    required this.icon,
    this.opensSecondaryPage = true,
  });

  String get title => titleKey.tr;

  String get subtitle => subtitleKey?.tr ?? '';
}
class SettingsSearchItem {
  final SettingsSection section;
  final List<TranslationKey> searchKeys;
  final List<String> searchAliases;
  final String searchId;

  const SettingsSearchItem({
    required this.section,
    this.searchKeys = const [],
    this.searchAliases = const [],
    this.searchId = '',
  });

  String get title {
    if (searchKeys.isNotEmpty) {
      return searchKeys.first.tr;
    }
    if (searchAliases.isNotEmpty) {
      return searchAliases.first;
    }
    return section.title;
  }

  String get subtitle => section.title;

  bool matches(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return false;
    }
    return [
      title,
      subtitle,
      section.subtitle,
      ...searchKeys.skip(1).map((key) => key.tr),
      ...searchAliases,
    ].any((text) => text.toLowerCase().contains(normalized));
  }
}

bool isSettingsSectionListVisible(SettingsSection section, bool isSmallScreen) {
  if (section == SettingsSection.language || section == SettingsSection.permission || section == SettingsSection.forward) {
    return false;
  }
  return isSettingsSectionAvailable(section, isSmallScreen);
}

bool isSettingsSectionAvailable(SettingsSection section, bool isSmallScreen) {
  if (section == SettingsSection.floatWindow) {
    return isAndroid || isIOS;
  }
  if (section == SettingsSection.permission) {
    return isAndroid || isIOS;
  }
  if (section == SettingsSection.hotKey) {
    return isDesktop;
  }
  if (section == SettingsSection.rules) {
    return isSmallScreen;
  }
  return true;
}
