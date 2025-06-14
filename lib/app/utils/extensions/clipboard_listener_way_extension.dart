import 'package:clipshare_clipboard_listener/enums.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';

extension ClipboardListeningWayExt on ClipboardListeningWay {
  String get tr {
    switch (this) {
      case ClipboardListeningWay.logs:
        return TranslationKey.clipboardListeningWithSystemLogs.tr;
      case ClipboardListeningWay.hiddenApi:
        return TranslationKey.clipboardListeningWithSystemHiddenApi.tr;
      default:
        return "Unknown";
    }
  }
}
