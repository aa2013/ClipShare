import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/utils/log.dart';

enum HistoryContentType {
  unknown(value: "unknown", order: 9999),
  all(value: "", order: 9999),
  text(value: "Text", order: 1),
  image(value: "Image", order: 2),
  richText(value: "RichText", order: 3),
  sms(value: "Sms", order: 4),
  file(value: "File", order: 5),
  notification(value: "Notification", order: 5);

  const HistoryContentType({
    required this.value,
    required this.order,
  });

  final String value;
  final int order;

  String get label {
    switch (this) {
      case HistoryContentType.unknown:
        return TranslationKey.unknownHistoryContentType.tr;
      case HistoryContentType.all:
        return TranslationKey.allHistoryContentType.tr;
      case HistoryContentType.text:
        return TranslationKey.textHistoryContentType.tr;
      case HistoryContentType.image:
        return TranslationKey.imageHistoryContentType.tr;
      case HistoryContentType.richText:
        return TranslationKey.richTextHistoryContentType.tr;
      case HistoryContentType.sms:
        return TranslationKey.smsHistoryContentType.tr;
      case HistoryContentType.file:
        return TranslationKey.fileHistoryContentType.tr;
      case HistoryContentType.notification:
        return TranslationKey.notification.tr;
    }
  }

  bool get isClipboard {
    switch (this) {
      case HistoryContentType.text:
      case HistoryContentType.image:
      case HistoryContentType.richText:
        return true;
      default:
        return false;
    }
  }

  static HistoryContentType parse(String value) => HistoryContentType.values.firstWhere(
        (e) => e.value.toUpperCase() == value.toUpperCase(),
        orElse: () {
          Log.debug("ContentType", "key '$value' unknown");
          return HistoryContentType.unknown;
        },
      );

  static Map<String, String> get typeMap {
    var lst = HistoryContentType.values.where((e) => e != HistoryContentType.unknown).toList();
    Map<String, String> res = {};
    for (var t in lst) {
      res[t.label] = t.value;
    }
    return res;
  }
}
