/// 存储中转的文件信息，与文件本体一同上传，接收端据此获取文件名与大小
class StorageFileInfo {
  /// 协议文件名，可携带相对路径
  final String fileName;

  /// 文件总大小
  final int size;

  const StorageFileInfo({
    required this.fileName,
    required this.size,
  });

  factory StorageFileInfo.fromJson(Map<String, dynamic> json) {
    return StorageFileInfo(
      fileName: json['fileName'] as String,
      size: (json['size'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fileName': fileName,
      'size': size,
    };
  }
}
