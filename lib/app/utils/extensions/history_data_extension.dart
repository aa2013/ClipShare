import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/repository/entity/tables/history.dart';
import 'package:clipshare/app/utils/extensions/string_extension.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare_clipboard_listener/clipboard_manager.dart';
import 'package:clipshare_clipboard_listener/enums.dart';
import 'package:flutter/cupertino.dart';

extension HistoryDataExtension on History {
  bool get canCopy {
    var type = ClipboardContentType.parse(this.type);
    if (type != ClipboardContentType.image &&
        type != ClipboardContentType.text) {
      if (extracted.isNullOrEmpty) {
        return false;
      }
      type = ClipboardContentType.text;
    }
    return true;
  }

  ClipboardContentType? getCopyType() {
    final canCopy = this.canCopy;
    if (!canCopy) {
      return null;
    }
    var type = ClipboardContentType.parse(this.type);
    if (type == ClipboardContentType.image) {
      return type;
    }
    return ClipboardContentType.text;
  }

  Future<void> copyContent({
    BuildContext? context,
    bool showFeedback = false,
  }) async {
    if (context == null && showFeedback) {
      throw 'context must be not null if show feedback';
    }
    if (!canCopy) {
      return;
    }
    final type = getCopyType();
    if (type == null) {
      return;
    }
    final content = extracted ?? this.content;
    final result = await clipboardManager.copy(type, content);
    if (!showFeedback) {
      return;
    }
    if (result) {
      Global.showSnackBarSuc(
        text: TranslationKey.copySuccess.tr,
        context: context,
      );
    } else {
      Global.showSnackBarErr(
        text: TranslationKey.copySuccess.tr,
        context: context,
      );
    }
  }
}
