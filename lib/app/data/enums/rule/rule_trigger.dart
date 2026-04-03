import 'package:clipshare/app/data/enums/history_content_type.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';

enum RuleTrigger {
  onCopy,
  onNotification,
  onSms;

  bool match(HistoryContentType type) {
    switch (this) {
      case RuleTrigger.onCopy:
        return type == HistoryContentType.text || type == HistoryContentType.image;
      case RuleTrigger.onNotification:
        return type == HistoryContentType.notification;
      case RuleTrigger.onSms:
        return type == HistoryContentType.sms;
    }
  }

  String get tr {
    switch (this) {
      case RuleTrigger.onCopy:
        return TranslationKey.ruleTriggerOnCopyText.tr;
      case RuleTrigger.onNotification:
        return TranslationKey.ruleTriggerOnNotificationText.tr;
      case RuleTrigger.onSms:
        return TranslationKey.ruleTriggerOnSmsText.tr;
    }
  }
}
