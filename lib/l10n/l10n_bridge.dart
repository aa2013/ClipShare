import 'package:flutter/widgets.dart';

import 'gen/app_localizations.dart';

/// 全局当前语言的翻译访问桥。
///
/// 为无 context 的调用点（如 `TranslationKey.tr`、枚举 getter）提供
/// 当前语言的 [AppLocalizations] 实例。由 [AppLocalizationsNotifier]（
/// l10n_provider.dart）在语言变化时写入，保证 UI 之外也能获取翻译文本。
///
/// 这是长期保留的全局状态源；后续若彻底移除代理，仅需替换调用方即可。
class L10nBridge {
  L10nBridge._();

  static AppLocalizations? _current;

  /// 当前语言对应的翻译对象；未初始化时兜底返回英语，避免启动早期崩溃。
  static AppLocalizations get current => _current ?? lookupAppLocalizations(const Locale('en'));

  /// 绑定当前翻译对象，语言切换时由 provider 调用。
  static void bind(AppLocalizations value) {
    _current = value;
  }

  /// 当前是否已绑定翻译对象。
  static bool get isBound => _current != null;
}
