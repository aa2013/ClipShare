import 'dart:io';

import 'package:clipshare/core/constants/app_constants.dart';
import 'package:clipshare/core/constants/platform_constants.dart';
import 'package:clipshare/core/constants/platform_constants.dart' as PlatformExt;
import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/extensions/file_extension.dart';
import 'package:clipshare/core/providers/settings/app_paths/app_paths_provider.dart';
import 'package:clipshare/core/providers/settings/quick/quick_settings.dart';
import 'package:clipshare/l10n/app_language.dart';
import 'package:clipshare/shared/enums/config_key.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:flutter/material.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'quick_settings_provider.g.dart';

const _tag = 'quickSettingsProvider';

@Riverpod(keepAlive: true)
Future<QuickSettings> quickSettings(Ref ref) async {
  final db = await ref.watch(appDbProvider.future);
  final startMini = await db.configDao.getConfigByKey(ConfigKey.startMini, false);
  final language = AppLanguage.fromStorageValue(
    await db.configDao.getConfigByKey(
      ConfigKey.appLanguage,
      AppLanguage.auto.storageValue,
    ),
  );
  final theme = await db.configDao.getConfigByKey(
    ConfigKey.appTheme,
    ThemeMode.system,
    convert: (value) {
      try {
        return ThemeMode.values.byName(value);
      } catch (err, stack) {
        logger.error(_tag, err, stack);
        return ThemeMode.system;
      }
    },
  );
  final isLaunchAtStartup = await _detectLaunchAtStartup(ref);
  return QuickSettings(
    language: language,
    launchAtStartup: isLaunchAtStartup,
    appTheme: theme,
    startMini: startMini,
  );
}

Future<bool> _detectLaunchAtStartup(Ref ref) async {
  if (!isDesktop) {
    return false;
  }
  final packageInfo = await PackageInfo.fromPlatform();
  launchAtStartup.setup(
    appName: packageInfo.appName,
    appPath: PlatformExt.startupExecutablePath,
  );
  final appPaths = await ref.read(appPathsProvider.future);
  final userStartupPath = appPaths.windowsUserStartUpDirPath;
  var isLaunchAtStartup = await launchAtStartup.isEnabled();
  final isSystem = isLaunchAtStartup;
  if (isWindows) {
    final startupPaths = <String>[
      windowsStartUpPath,
    ];
    if (userStartupPath != null) {
      startupPaths.add(userStartupPath);
    }
    for (var startupPath in startupPaths) {
      final dir = Directory(startupPath);
      if (!dir.existsSync()) continue;
      final hasShortcut = await dir.existsTargetFileShortcut(
        Platform.resolvedExecutable,
      );
      isLaunchAtStartup = isLaunchAtStartup || hasShortcut;
    }
  }
  logger.debug(_tag, 'isLaunchAtStartup $isLaunchAtStartup, isSystem $isSystem');
  if (isLaunchAtStartup && isSystem) {
    await deleteWindowsLaunchAtStartupShortcut(userStartupPath);
  }
  return isLaunchAtStartup;
}

Future<void> deleteWindowsLaunchAtStartupShortcut(String? windowsUserStartUpDirPath) async {
  if (!isWindows) {
    return;
  }
  final startupPaths = <String>[
    windowsStartUpPath,
  ];
  if (windowsUserStartUpDirPath != null) {
    startupPaths.add(windowsUserStartUpDirPath);
  }
  for (var startupPath in startupPaths) {
    final dir = Directory(startupPath);
    if (!dir.existsSync()) continue;
    await dir.deleteTargetFileShortcut(
      Platform.resolvedExecutable,
    );
  }
}
