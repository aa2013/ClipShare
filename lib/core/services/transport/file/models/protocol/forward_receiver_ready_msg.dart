import 'dart:typed_data';

import 'package:clipshare/core/services/transport/enums/forward_msg_type.dart';
import 'package:clipshare/core/services/transport/file/models/protocol/forward_packet_codec.dart';

/// 中转通道接收就绪消息（connType=recFile）：
/// 接收端连上中转服务器后告知发送端可以开始传输文件流
class ForwardReceiverReadyMsg {
  /// 发送端设备 id
  final String targetDevId;

  /// 协议文件 id
  final int fileId;

  /// 接收端（本机）设备 id
  final String selfDevId;

  const ForwardReceiverReadyMsg({
    required this.targetDevId,
    required this.fileId,
    required this.selfDevId,
  });

  Map<String, dynamic> toJson() {
    return {
      'connType': ForwardConnType.recFile.name,
      'target': targetDevId,
      'fileId': fileId.toString(),
      'self': selfDevId,
    };
  }

  /// 按中转协议编码为带包头的数据包
  Uint8List encodePacket() {
    return encodeForwardPacket(toJson());
  }
}
