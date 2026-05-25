import 'package:clipshare/app/data/enums/translation_key.dart';

enum WhiteBlackMode {
  white,
  black,
  defaultMode;

  String get tr {
    switch (this) {
      case WhiteBlackMode.white:
        return TranslationKey.ruleDetailModeWhitelist.tr;
      case WhiteBlackMode.black:
        return TranslationKey.ruleDetailModeBlacklist.tr;
      case WhiteBlackMode.defaultMode:
        return TranslationKey.ruleDetailModeDefault.tr;
    }
  }
}
