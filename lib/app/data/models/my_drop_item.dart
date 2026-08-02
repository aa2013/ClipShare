import 'dart:typed_data';

/// 待发送文件列表使用的拖入项基础模型，隔离外部拖拽插件的具体类型。
class DropItem {
  final String path;
  final String name;
  final String? mimeType;
  final int? size;
  final Uint8List? bytes;
  final DateTime? lastModified;
  final Uint8List? extraAppleBookmark;

  DropItem(
    this.path, {
    String? name,
    this.mimeType,
    this.size,
    this.bytes,
    this.lastModified,
    this.extraAppleBookmark,
  }) : name = name ?? _fileNameFromPath(path);

  /// 是否为远端 URI 文件项；此类项目不能通过本地文件系统直接读取大小。
  bool get isUri => mimeType == "uri";

  /// 返回文件大小，URI 项使用构造时记录的 size，本地文件由调用方按需读取。
  Future<int> length() {
    return Future.value(size ?? 0);
  }
}

/// 本地文件或文件夹拖入项。
class DropItemFile extends DropItem {
  DropItemFile(super.filePath) : super(name: _fileNameFromPath(filePath));
}

/// URI 文件拖入项，用于系统分享或外部 URI 转发来的待发送文件。
class DropItemFileUri extends DropItem {
  final String uri;
  final String fileName;
  final int fileSize;

  DropItemFileUri(
    this.uri,
    this.fileName,
    this.fileSize, {
    Uint8List? bytes,
    DateTime? lastModified,
    Uint8List? extraAppleBookmark,
  }) : super(
         uri,
         mimeType: "uri",
         name: fileName,
         size: fileSize,
         bytes: bytes,
         lastModified: lastModified,
         extraAppleBookmark: extraAppleBookmark,
       );

  @override
  Future<int> length() {
    return Future.value(fileSize);
  }
}

/// 从跨平台路径中提取文件名，避免待发送列表依赖外部路径工具包。
String _fileNameFromPath(String value) {
  final parts = value.split(RegExp(r'(/+|\\+)')).where((part) => part.isNotEmpty);
  return parts.isEmpty ? value : parts.last;
}