import 'dart:convert';
import 'dart:typed_data';

import 'package:clipshare/core/database/app_database.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/enums/history_content_type.dart';
import 'package:clipshare/shared/extensions/number_extension.dart';
import 'package:clipshare/shared/extensions/string_extension.dart';
import 'package:clipshare/shared/extensions/time_extension.dart';
import 'package:clipshare/shared/utils/log.dart';

const _historyExtTag = 'HistoryExt';
final _notificationCacheExpando = Expando<_HistoryNotificationCache>(
  'historyNotificationCache',
);

/// 历史通知内容解析缓存。
///
/// Drift 生成的 History 不承载展示态字段，通知 JSON 与图片解码结果通过 Expando 按实例缓存。
class _HistoryNotificationCache {
  /// 通知内容 JSON 解析结果。
  final Map<String, dynamic> contentMap;

  /// 通知携带的图片，来源为 JSON 中的 base64 img 字段。
  final Uint8List? image;

  const _HistoryNotificationCache({
    required this.contentMap,
    this.image,
  });
}

/// 历史行对象的业务扩展，真实数据类由 Drift 生成。
extension HistoryExt on History {
  /// 深拷贝历史记录，沿用 Drift 生成的 JSON 序列化结构。
  History copy() => History.fromJson(toJson());

  /// 是否是图片历史。
  bool get isImage => type == HistoryContentType.image.value;

  /// 是否是文本历史。
  bool get isText => type == HistoryContentType.text.value;

  /// 是否是文件历史。
  bool get isFile => type == HistoryContentType.file.value;

  /// 是否是短信历史。
  bool get isSms => type == HistoryContentType.sms.value;

  /// 是否是通知历史。
  bool get isNotification => type == HistoryContentType.notification.value;

  /// 是否是富文本历史。
  bool get isRichText => type == HistoryContentType.richText.value;

  /// 是否存在规则提取内容。
  bool get hasExtracted => extracted.isNotNullAndEmpty;

  /// 历史记录展示时间。
  String get timeStr => getTimeStr();

  /// 通知内容 JSON 解析结果，非通知或解析失败时返回空 Map。
  Map<String, dynamic> get notificationContentMap => _notificationCache.contentMap;

  /// 通知携带的图片，非通知或图片解码失败时为空。
  Uint8List? get notificationImage => _notificationCache.image;

  /// 通知标题与正文组合后的展示文本。
  String? get notificationContent {
    if (!isNotification) {
      return null;
    }
    try {
      final title = notificationContentMap['title']?.toString() ?? '';
      final detail = notificationContentMap['content'] as String? ?? '';
      return '$title\n$detail';
    } catch (err, stack) {
      logger.error(_historyExtTag, err, stack);
      return null;
    }
  }

  /// 历史记录展示大小。
  ///
  /// 文本类记录按字符数展示，文件类记录按字节大小展示；通知按标题和正文长度重新计算。
  String get sizeText {
    var displaySize = size;
    if (isText || isRichText || isSms || isNotification) {
      if (isNotification) {
        final title = notificationContentMap['title'] as String? ?? '';
        final content = notificationContentMap['content'] as String? ?? '';
        displaySize = title.length + content.length;
      }
      return '$displaySize ${TranslationKey.unitWord.tr}';
    }
    return displaySize.sizeStr;
  }

  /// 获取历史记录的相对时间文案。
  String getTimeStr() {
    return DateTime.parse(time).simpleStr;
  }

  /// 获取通知解析缓存，首次访问时解析 JSON 与图片字段。
  _HistoryNotificationCache get _notificationCache {
    final cached = _notificationCacheExpando[this];
    if (cached != null) {
      return cached;
    }
    final cache = _parseNotificationCache();
    _notificationCacheExpando[this] = cache;
    return cache;
  }

  /// 解析通知 JSON，异常时返回空缓存并记录日志。
  _HistoryNotificationCache _parseNotificationCache() {
    if (!isNotification) {
      return const _HistoryNotificationCache(contentMap: {});
    }
    try {
      final decoded = jsonDecode(content);
      final contentMap = decoded is Map ? decoded.map((key, value) => MapEntry(key.toString(), value)) : <String, dynamic>{};
      final imageContent = contentMap['img'];
      Uint8List? image;
      if (imageContent is String && imageContent.isNotEmpty) {
        image = base64Decode(imageContent);
      }
      return _HistoryNotificationCache(contentMap: contentMap, image: image);
    } catch (err, stack) {
      logger.error(_historyExtTag, err, stack);
      return const _HistoryNotificationCache(contentMap: {});
    }
  }
}
