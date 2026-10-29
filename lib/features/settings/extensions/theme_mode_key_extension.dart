import 'package:clipshare/l10n/translation_key.dart';
import 'package:flutter/material.dart';

extension ThemeModeExt on ThemeMode {

  TranslationKey get tk {
    switch (this) {
      case ThemeMode.system:
        return TranslationKey.themeAuto;
      case ThemeMode.light:
        return TranslationKey.themeLight;
      case ThemeMode.dark:
        return TranslationKey.themeDark;
      }
  }
}