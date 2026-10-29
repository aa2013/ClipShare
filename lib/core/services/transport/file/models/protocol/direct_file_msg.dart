/// 直连通道文件控制消息（MsgType.file）：
/// 通知对端本机已开启临时数据端口，由对端反连拉取文件流
class DirectFileMsg {
  /// 协议文件名，可携带相对路径
  final String fileName;

  /// 文件总大小
  final int size;

  /// 发送端临时数据端口
  final int port;

  /// 协议文件 id
  final int fileId;

  const DirectFileMsg({
    required this.fileName,
    required this.size,
    required this.port,
    required this.fileId,
  });

  factory DirectFileMsg.fromJson(Map<String, dynamic> json) {
    return DirectFileMsg(
      fileName: json['fileName'] as String,
      size: (json['size'] as num).toInt(),
      port: (json['port'] as num).toInt(),
      fileId: (json['fileId'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fileName': fileName,
      'size': size,
      'port': port,
      'fileId': fileId,
    };
  }
}
