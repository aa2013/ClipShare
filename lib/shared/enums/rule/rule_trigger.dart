import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/enums/history_content_type.dart';

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
