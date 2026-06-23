import 'dart:convert';

import 'package:floor/floor.dart';

@entity
class PendingStorageAck {
  ///操作记录 id
  @primaryKey
  late int opId;

  ///目标设备 id
  @primaryKey
  late String targetDevId;


  PendingStorageAck({
    required this.opId,
    required this.targetDevId,
  });

  factory PendingStorageAck.fromJson(Map<String, dynamic> json) {
    return PendingStorageAck(
      opId: json["opId"],
      targetDevId: json["targetDevId"],
    );
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }

  Map<String, dynamic> toJson() {
    return {
      "opId": opId,
      "targetDevId": targetDevId,
    };
  }
}
