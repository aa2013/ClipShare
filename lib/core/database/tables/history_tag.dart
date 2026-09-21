import '../app_database.dart';

export '../app_database.dart' show HistoryTag;

/// 新建历史标签，默认使用雪花 id 保持旧业务主键生成方式。
HistoryTag newHistoryTag(int id, String tagName, int hisId) {
  return HistoryTag(
    id: id,
    tagName: tagName,
    hisId: hisId,
  );
}

/// 构造空标签占位，供缺失数据同步删除流程使用。
HistoryTag emptyHistoryTag({int id = 0, String tagName = '', int hisId = 0}) {
  return HistoryTag(id: id, tagName: tagName, hisId: hisId);
}
