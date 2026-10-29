import 'dart:convert';
import 'dart:typed_data';

import 'package:clipshare/core/services/transport/client/socket/secure_socket_client.dart';

/// 将中转协议 json 消息编码为单个带 10 字节包头的数据包
Uint8List encodeForwardPacket(Map<String, dynamic> json) {
  final payload = utf8.encode(jsonEncode(json));
  final msgSize = payload.length;
  final header = SecureSocketClient.createPacketHeader(msgSize, msgSize, 1, 1);
  final packet = Uint8List(header.length + payload.length);
  packet.setAll(0, header);
  packet.setAll(header.length, payload);
  return packet;
}
