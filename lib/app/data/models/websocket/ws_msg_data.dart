import 'dart:convert';

import 'package:clipshare/app/data/models/websocket/ws_msg_type.dart';

class WsMsgData {
  final WsMsgType operation;
  final String data;
  final String targetDevId;

  WsMsgData(this.operation, this.data, this.targetDevId);

  factory WsMsgData.fromJson(Map<String, dynamic> json) {
    return WsMsgData(WsMsgType.getValue(json["operation"]), json["data"], json["targetDevId"]);
  }

  Map<String, dynamic> toJson() {
    return {
      "operation": operation.name,
      "data": data,
      "targetDevId": targetDevId,
    };
  }

  @override
  String toString() {
    return jsonEncode(this);
  }
}
