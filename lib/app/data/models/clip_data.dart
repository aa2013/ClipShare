import 'dart:convert';
import 'dart:typed_data';

import 'package:clipshare/app/data/enums/history_content_type.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/repository/entity/tables/history.dart';
import 'package:clipshare/app/utils/extensions/number_extension.dart';
import 'package:clipshare/app/utils/extensions/string_extension.dart';
import 'package:clipshare/app/utils/extensions/time_extension.dart';
import 'package:flutter/widgets.dart';

class ClipData implements Comparable<ClipData> {
  ClipData(this._data) {
    _refreshNotificationCache();
  }

  History _data;

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

  /// 替换展示包装中的历史行对象，供 Drift 不可变数据类做局部 UI 更新。
  set data(History value) {
    _data = value;
    _refreshNotificationCache();
  }

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

  bool get hasExtracted => _data.extracted.isNotNullAndEmpty;

  /// 通知类型的内容需要预解析图片和文本，替换数据时必须同步刷新缓存。
  void _refreshNotificationCache() {
    _notificationImage = null;
    _notificationContent = null;
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
  int compareTo(ClipData other) {
    //置顶优先，同置顶状态下按 id 降序
    if (data.top && !other.data.top) {
      return -1;
    } else if (!data.top && other.data.top) {
      return 1;
    }
    return other.data.id.compareTo(data.id);
  }

  @override
  int get hashCode => _data.id.hashCode;

  @override
  bool operator ==(Object other) {
    if (other is History) {
      return _data.id == other.id;
    } else if (other is ClipData) {
      return _data.id == other._data.id;
    }
    return false;
  }
}
