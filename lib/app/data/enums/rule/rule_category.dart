import 'package:clipshare/app/data/enums/translation_key.dart';

enum RuleCategory {
  all,
  common,
  tag,
  sms,
  notification,
  unknown;

  String get tr {
    switch (this) {
      case RuleCategory.all:
        return TranslationKey.all.tr;
      case RuleCategory.common:
        return "普通";
      case RuleCategory.tag:
        return "标签";
      case RuleCategory.sms:
        return "短信";
      case RuleCategory.notification:
        return "通知";
      default:
        return name;
    }
  }
}
