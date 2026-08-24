import '../app_database.dart';

export '../app_database.dart' show OperationSync;

/// 新建同步确认记录，默认使用当前时间保持旧构造器语义。
OperationSync newOperationSync({
  required int opId,
  required String devId,
  required int uid,
  String? time,
}) {
  return OperationSync(
    opId: opId,
    devId: devId,
    uid: uid,
    time: time ?? DateTime.now().toString(),
  );
}

/// 从旧备份 JSON 还原同步记录，缺失 time 时使用当前时间保持旧构造语义。
OperationSync operationSyncFromJson(Map<String, dynamic> map) {
  return newOperationSync(
    opId: map['opId'],
    devId: map['devId'],
    uid: map['uid'],
    time: map['time'] ?? DateTime.now().toString(),
  );
}
