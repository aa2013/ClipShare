import 'dart:ui';

import 'package:clipshare/core/providers/settings/quick/quick_settings_provider.dart';
import 'package:clipshare/l10n/app_language.dart';
import 'package:clipshare/l10n/l10n_bridge.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'gen/app_localizations.dart';

/// 当前应用界面语言（已解析系统语言，供 MaterialApp 使用）。
final uiLocaleProvider = Provider<Locale>((ref) {
  final language = ref.watch(languageProvider).when(
    data: (lang) => lang,
    loading: () => AppLanguage.auto,
    error: (_, __) => AppLanguage.auto,
  );
  final deviceLocale = PlatformDispatcher.instance.locale;
  return language.resolveLocale(deviceLocale);
});

/// 当前生效的翻译对象，绑定到 [L10nBridge] 供无 context 调用点使用。
final appLocalizationsProvider = Provider<AppLocalizations>((ref) {
  final locale = ref.watch(uiLocaleProvider);
  final l10n = lookupAppLocalizations(locale);
  L10nBridge.bind(l10n);
  return l10n;
});
