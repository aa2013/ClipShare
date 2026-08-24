import 'dart:ui';

import 'package:clipshare/l10n/app_language.dart';
import 'package:clipshare/l10n/l10n_bridge.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'gen/app_localizations.dart';

/// 当前界面的语言状态。
///
/// 默认为跟随系统；界面切换语言时由 [LocaleNotifier] 更新。持久化暂未接入，
/// 后续在 settings 模块完成语言配置读写后回填。
class LocaleNotifier extends Notifier<AppLanguage> {
  @override
  AppLanguage build() => AppLanguage.auto;

  /// 切换语言；自动跟随系统时传入 [AppLanguage.auto]。
  void setLanguage(AppLanguage language) {
    state = language;
  }
}

/// 当前选择的语言偏好（auto / zhCN / enUS）。
final localeProvider = NotifierProvider<LocaleNotifier, AppLanguage>(
  LocaleNotifier.new,
);

/// 当前应用界面语言（已解析系统语言，供 MaterialApp 使用）。
final uiLocaleProvider = Provider<Locale>((ref) {
  final language = ref.watch(localeProvider);
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
