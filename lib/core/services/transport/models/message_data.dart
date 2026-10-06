import 'dart:convert';

import 'package:clipshare/core/services/device/local_device_info.dart';

import '../enums/msg_type.dart';

class MessageData {
  BaseDeviceInfo send;
  BaseDeviceInfo? recv;
  MsgType key;
  Map<String, dynamic> data;

  MessageData({
    required this.send,
    required this.key,
    required this.data,
    this.recv,
  });

  static MessageData fromJson(Map<String, dynamic> map) {
    BaseDeviceInfo devInfo = BaseDeviceInfo.fromJson(
      (map['send'] as Map<dynamic, dynamic>).cast<String, dynamic>(),
    );
    BaseDeviceInfo? recv = map['recv'] != null
        ? BaseDeviceInfo.fromJson(
            (map['recv'] as Map<dynamic, dynamic>).cast<String, dynamic>(),
          )
        : null;
    MsgType key = MsgType.getValue(map['key']);
    Map<dynamic, dynamic> data = map['data'];
    return MessageData(
      send: devInfo,
      key: key,
      data: data.cast<String, dynamic>(),
      recv: recv,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': 0, //兼容旧版本，实际上没有用
      'send': send.toJson(),
      'recv': recv?.toJson(),
      'key': key.name,
      'data': jsonDecode(jsonEncode(data)),
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
