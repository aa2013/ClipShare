import 'dart:io';

import 'package:clipshare/app/modules/settings_module/settings_section.dart';
import 'package:clipshare/app/utils/extensions/platform_extension.dart';

bool isSettingsSectionListVisible(SettingsSection section, bool isSmallScreen) {
  if (section == SettingsSection.language || section == SettingsSection.permission || section == SettingsSection.forward) {
    return false;
  }
  return isSettingsSectionAvailable(section, isSmallScreen);
}

bool isSettingsSectionAvailable(SettingsSection section, bool isSmallScreen) {
  if (section == SettingsSection.floatWindow) {
    return Platform.isAndroid || Platform.isIOS;
  }
  if (section == SettingsSection.permission) {
    return Platform.isAndroid || Platform.isIOS;
  }
  if (section == SettingsSection.hotKey) {
    return PlatformExt.isDesktop;
  }
  if (section == SettingsSection.rules) {
    return isSmallScreen;
  }
  return true;
}
