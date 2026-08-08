import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare_clipboard_listener/enums.dart';

extension PasteWindowResultExtension on PasteResult {
  String get tr {
    switch (this) {
      case PasteResult.success:
        return TranslationKey.success.tr;
      case PasteResult.noTargetWindow:
        return TranslationKey.noTargetWindow.tr;
      case PasteResult.openTargetProcessFailed:
        return TranslationKey.openTargetProcessFailed.tr;
      case PasteResult.inspectTargetFailed:
        return TranslationKey.inspectTargetFailed.tr;
      case PasteResult.inspectSelfFailed:
        return TranslationKey.inspectSelfFailed.tr;
      case PasteResult.targetIntegrityHigher:
        return TranslationKey.targetIntegrityHigher.tr;
      case PasteResult.unknown:
        return TranslationKey.unknown.tr;
    }
  }
}
