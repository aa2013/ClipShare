import 'dart:io';

import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/repository/entity/tables/history.dart';
import 'package:clipshare/app/utils/extensions/file_extension.dart';
import 'package:clipshare/app/utils/extensions/platform_extension.dart';
import 'package:clipshare/app/utils/extensions/string_extension.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:clipshare_clipboard_listener/clipboard_manager.dart';
import 'package:clipshare_clipboard_listener/enums.dart';
import 'package:flutter/cupertino.dart';
import 'package:super_clipboard/super_clipboard.dart';

extension HistoryDataExtension on History {
  static const String tag = "HistoryDataExtension";
  bool get canCopy {
    var type = ClipboardContentType.parse(this.type);
    if (type != ClipboardContentType.image &&
        type != ClipboardContentType.text) {
      if(type == ClipboardContentType.file && PlatformExt.isDesktop){
        return true;
      }
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
    if (type == ClipboardContentType.image || type == ClipboardContentType.file) {
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
    bool copyResult;
    if (type == ClipboardContentType.file) {
      final superClipboard = SystemClipboard.instance;
      final file = File(content);
      if (superClipboard == null) {
        copyResult = false;
        logger.warn(tag, "copy file failed: superClipboard is null");
      } else if (!await file.exists()) {
        logger.warn(tag, "copy file failed: $content, file not exists");
        copyResult = false;
      } else {
        final item = DataWriterItem(
          suggestedName: file.fileName,
        );
        item.add(
          Formats.fileUri(file.uri),
        );
        try {
          await superClipboard.write([item]);
          copyResult = true;
        } catch (err, stack) {
          logger.error(tag, err, stack);
          copyResult = false;
        }
      }
    } else {
      copyResult = await clipboardManager.copy(type, content);
    }
    if (!showFeedback) {
      return;
    }
    if (copyResult) {
      Global.showSnackBarSuc(
        text: TranslationKey.copySuccess.tr,
        context: context,
      );
    } else {
      Global.showSnackBarErr(
        text: TranslationKey.copyFailed.tr,
        context: context,
      );
    }
  }
}
