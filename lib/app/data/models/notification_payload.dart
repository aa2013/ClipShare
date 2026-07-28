import 'dart:convert';

import 'package:clipshare/app/data/enums/notification_payload_type.dart';

/// 系统通知点击后的业务载荷
class NotificationPayload {
  /// data 中保存文件路径时使用的字段名。
  static const filePathKey = 'path';

  final NotificationPayloadType type;
  final Map<String, dynamic> data;

  const NotificationPayload({
    required this.type,
    required this.data,
  });

  /// 根据插件回传的 JSON 还原业务载荷。
  factory NotificationPayload.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    return NotificationPayload(
      type: NotificationPayloadType.values.byName(json['type'].toString()),
      data: rawData is Map ? rawData.cast<String, dynamic>() : <String, dynamic>{},
    );
  }

  factory NotificationPayload.fromJsonString(String payload) {
    return NotificationPayload.fromJson((jsonDecode(payload) as Map).cast<String, dynamic>());
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'data': data,
    };
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}
