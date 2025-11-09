import 'dart:convert';

import 'package:clipshare/app/data/enums/msg_type.dart';
import 'package:clipshare/app/data/models/dev_info.dart';
import 'package:clipshare/app/utils/log.dart';

class MessageData {
  int userId;
  DevInfo send;
  DevInfo? recv;
  MsgType key;
  Map<String, dynamic> data;

  MessageData({
    required this.userId,
    required this.send,
    required this.key,
    required this.data,
    this.recv,
  });

  static MessageData fromJson(Map<String, dynamic> map) {
    int userId = map["userId"];
    DevInfo devInfo = DevInfo.fromJson(
      (map["send"] as Map<dynamic, dynamic>).cast<String, dynamic>(),
    );
    DevInfo? recv = map["recv"] != null
        ? DevInfo.fromJson(
            (map["recv"] as Map<dynamic, dynamic>).cast<String, dynamic>(),
          )
        : null;
    MsgType key = MsgType.getValue(map["key"]);
    Map<dynamic, dynamic> data = map["data"];
    return MessageData(
      userId: userId,
      send: devInfo,
      key: key,
      data: data.cast<String, dynamic>(),
      recv: recv,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "userId": userId,
      "send": send.toJson(),
      "recv": recv?.toJson(),
      "key": key.name,
      "data": jsonDecode(jsonEncode(data)),
    };
  }

  @override
  String toString() {
    return toJsonStr();
  }

  String toJsonStr() {
    return jsonEncode(toJson());
  }
}
