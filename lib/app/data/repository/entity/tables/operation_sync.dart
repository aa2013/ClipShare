import 'dart:convert';

import 'package:floor/floor.dart';

@Entity(
  primaryKeys: ['opId', 'devId', 'uid'],
  tableName: "OperationSync",
)
class OperationSync {
  ///操作记录 id
  @primaryKey
  int opId;

  ///设备 id
  @primaryKey
  String devId;

  /// 用户 id
  @primaryKey
  int uid;

  ///同步时间
  String time = DateTime.now().toString();

  OperationSync({
    required this.opId,
    required this.devId,
    required this.uid,
  });

  factory OperationSync.fromJson(Map<String, dynamic> map) {
    return OperationSync(
      opId: map["opId"],
      devId: map["devId"],
      uid: map["uid"],
    );
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }

  Map<String, dynamic> toJson() {
    return {
      "opId": opId,
      "devId": devId,
      "uid": uid,
    };
  }
}
