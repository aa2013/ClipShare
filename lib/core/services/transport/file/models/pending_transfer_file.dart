/// 待发送文件条目，入队前已解析好文件名、大小与相对目录层级
class PendingTransferFile {
  /// 本机文件路径，Android 系统分享场景为 content uri
  final String filePath;

  /// [filePath] 是否为 content uri
  final bool isUri;

  /// 该条目是否为文件夹（发送时再展开内部文件）
  final bool isDirectory;

  /// 文件名（不含目录；文件夹条目为文件夹名）
  final String fileName;

  /// 文件大小，文件夹条目为 0
  final int size;

  /// 相对发送根目录的目录层级，如拖入文件夹 a/b 中的 c.txt 为 ['a', 'b']
  final List<String> relativeDirs;

  const PendingTransferFile({
    required this.filePath,
    this.isUri = false,
    this.isDirectory = false,
    required this.fileName,
    required this.size,
    this.relativeDirs = const [],
  });
}
