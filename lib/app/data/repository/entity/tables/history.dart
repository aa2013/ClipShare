import '../../db/app_database.dart';

export '../../db/app_database.dart' show History;

/// 构造空历史对象，供缺失数据同步流程作为删除占位使用。
History emptyHistory({
  int id = 0,
  int uid = 0,
  String time = '',
  String content = '',
  String type = '',
  String devId = '',
  bool top = false,
  bool sync = false,
  int size = 0,
  String? updateTime,
  String? source,
  String? extracted,
}) {
  return History(
    id: id,
    uid: uid,
    time: time,
    content: content,
    extracted: extracted,
    type: type,
    devId: devId,
    top: top,
    sync: sync,
    size: size,
    updateTime: updateTime,
    source: source,
  );
}

/// 将窗口通信中的 JSON 列表还原为 Drift 历史数据类。
List<History> historyListFromJson(List<dynamic> jsonList) {
  return jsonList.map((map) => History.fromJson((map as Map).cast<String, dynamic>())).toList(growable: true);
}

/// 历史行对象的业务扩展，真实数据类由 Drift 生成。
extension HistoryExt on History {
  /// 深拷贝历史记录，沿用 Drift 生成的 JSON 序列化结构。
  History copy() => History.fromJson(toJson());
}
