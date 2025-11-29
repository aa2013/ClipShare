import 'dart:convert';
import 'dart:typed_data';

import 'package:clipshare/app/data/enums/history_content_type.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/repository/entity/tables/history.dart';
import 'package:clipshare/app/utils/extensions/number_extension.dart';
import 'package:clipshare/app/utils/extensions/time_extension.dart';
import 'package:flutter/widgets.dart';

class ClipData {
  ClipData(this._data) {
    if (isNotification) {
      try {
        var json = jsonDecode(_data.content);
        _notificationContent = json;
        if (json["img"] != null) {
          _notificationImage = base64Decode(json["img"]);
        }
      } catch (err, stack) {
        debugPrint(err.toString());
        debugPrintStack(stackTrace: stack);
      }
    }
  }

  final History _data;

  Uint8List? _notificationImage;

  Uint8List? get notificationImage => _notificationImage;

  Map? _notificationContent;

  Map get notificationContentMap => _notificationContent ?? {};

  String? get notificationContent {
    try {
      var title = notificationContentMap["title"] ?? "";
      var detail = (notificationContentMap["content"] as String? ?? "");
      return "$title\n$detail";
    } catch (err, stack) {
      debugPrint(err.toString());
      debugPrintStack(stackTrace: stack);
      return null;
    }
  }

  History get data => _data;

  bool get isImage => _data.type == HistoryContentType.image.value;

  bool get isText => _data.type == HistoryContentType.text.value;

  bool get isFile => _data.type == HistoryContentType.file.value;

  bool get isSms => _data.type == HistoryContentType.sms.value;

  bool get isNotification => _data.type == HistoryContentType.notification.value;

  String get timeStr => getTimeStr();

  bool get isRichText => _data.type == HistoryContentType.richText.value;

  String get sizeText {
    var size = data.size;
    if (isText || isRichText || isSms || isNotification) {
      if (isNotification) {
        final title = notificationContentMap["title"] as String? ?? "";
        final content = notificationContentMap["content"] as String? ?? "";
        size = title.length + content.length;
      }
      return "$size ${TranslationKey.unitWord.tr}";
    }
    return size.sizeStr;
  }

  String getTimeStr() {
    return DateTime.parse(data.time).simpleStr;
  }

  static List<ClipData> fromList(List<History> list) {
    List<ClipData> res = List.empty(growable: true);
    for (int i = 0; i < list.length; i++) {
      res.add(ClipData(list[i]));
    }
    return res;
  }

  @override
  int get hashCode => _data.hashCode;

  @override
  bool operator ==(Object other) {
    if (other is History) {
      return _data == other;
    } else if (other is ClipData) {
      return _data == other._data;
    }
    return false;
  }
}
