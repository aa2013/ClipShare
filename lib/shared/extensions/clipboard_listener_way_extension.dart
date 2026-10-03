import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare_clipboard_listener/enums.dart';
import 'package:flutter/material.dart';

extension ClipboardListeningWayExt on ClipboardListeningWay {
  String get tr {
    switch (this) {
      case ClipboardListeningWay.logs:
        return TranslationKey.clipboardListeningWithSystemLogs.tr;
      case ClipboardListeningWay.hiddenApi:
        return TranslationKey.clipboardListeningWithSystemHiddenApi.tr;
      default:
        return TranslationKey.unknown.tr;
    }
  }

  /// 监听方式图标
  IconData get icon {
    return switch (this) {
      ClipboardListeningWay.logs => Icons.list_alt,
      ClipboardListeningWay.hiddenApi => Icons.visibility_off,
    };
  }
}
