import 'dart:typed_data';

import 'package:clipshare/core/services/transport/enums/forward_msg_type.dart';
import 'package:clipshare/core/services/transport/file/models/protocol/forward_packet_codec.dart';

/// 中转通道发送请求（connType=sendFile）：
/// 发送端在独立的文件连接上告知中转服务器目标设备与文件信息
class ForwardSendFileMsg {
  /// 协议文件名，可携带相对路径
  final String fileName;

  /// 文件总大小
  final int size;

  /// 协议文件 id
  final int fileId;

  /// 接收端设备 id
  final String targetDevId;

  /// 发送端设备 id
  final String selfDevId;

  const ForwardSendFileMsg({
    required this.fileName,
    required this.size,
    required this.fileId,
    required this.targetDevId,
    required this.selfDevId,
  });

  Map<String, dynamic> toJson() {
    return {
      'fileName': fileName,
      'size': size.toString(),
      'fileId': fileId.toString(),
      'target': targetDevId,
      'connType': ForwardConnType.sendFile.name,
      'self': selfDevId,
      'userId': '0',
    };
  }

  /// 按中转协议编码为带包头的数据包
  Uint8List encodePacket() {
    return encodeForwardPacket(toJson());
  }
}
