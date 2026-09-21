import 'package:clipshare/l10n/app_language.dart';
import 'package:flutter/material.dart';

class QuickSettings {
  ///开启启动
  final bool launchAtStartup;

  ///启动最小化
  final bool startMini;

  ///主题
  final ThemeMode appTheme;

  ///语言
  final AppLanguage language;

  const QuickSettings({
    this.launchAtStartup = false,
    this.startMini = false,
    this.appTheme = ThemeMode.system,
    this.language = AppLanguage.auto,
  });
}
