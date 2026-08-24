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

/// 聚合快捷设置分区所需状态，字段来源保持独立以便单项设置刷新时只失效对应缓存。
@Riverpod(keepAlive: true)
Future<QuickSettings> quickSettings(Ref ref) async {
  final language = await ref.watch(languageProvider.future);
  final launchAtStartup = await ref.watch(appLaunchAtStartupProvider.future);
  final appTheme = await ref.watch(appThemeProvider.future);
  final startMini = await ref.watch(startMiniProvider.future);
  return QuickSettings(
    language: language,
    launchAtStartup: launchAtStartup,
    appTheme: appTheme,
    startMini: startMini,
  );
}

/// 读取当前开机启动状态；该检测包含平台查询，只有开机启动配置变化时才应主动刷新。
@Riverpod(keepAlive: true)
Future<bool> appLaunchAtStartup(Ref ref) async {
  return _detectLaunchAtStartup(ref);
}

/// 读取启动最小化偏好，供快捷设置 UI 和桌面启动窗口展示逻辑复用。
@Riverpod(keepAlive: true)
Future<bool> startMini(Ref ref) async {
  final db = await ref.watch(appDbProvider.future);
  return db.configDao.getConfigByKey(ConfigKey.startMini, false);
}

/// 读取应用语言偏好，返回已解析的语言枚举以便 UI 直接展示生效选项。
@Riverpod(keepAlive: true)
Future<AppLanguage> language(Ref ref) async {
  final db = await ref.watch(appDbProvider.future);
  final storageValue = await db.configDao.getConfigByKey(
    ConfigKey.appLanguage,
    AppLanguage.auto.storageValue,
  );
  return AppLanguage.fromStorageValue(storageValue);
}

/// 读取应用主题模式偏好，供启动主题、系统主题同步和设置页选择器共用。
@Riverpod(keepAlive: true)
Future<ThemeMode> appTheme(Ref ref) async {
  final db = await ref.watch(appDbProvider.future);
  return db.configDao.getConfigByKey(
    ConfigKey.appTheme,
    ThemeMode.system,
    convert: _parseThemeMode,
  );
}

/// 解析持久化主题模式；非法值回退到跟随系统，避免损坏配置阻断启动。
ThemeMode _parseThemeMode(String value) {
  try {
    return ThemeMode.values.byName(value);
  } catch (err, stack) {
    logger.error(_tag, err, stack);
    return ThemeMode.system;
  }
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
