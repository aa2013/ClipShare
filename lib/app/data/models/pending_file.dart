class PendingFile {
  final bool isDirectory;
  final String filePath;
  final String? fileName;
  final int? size;
  final bool isUri;
  final List<String> directories;

  const PendingFile({
    required this.isDirectory,
    required this.filePath,
    required this.directories,
    this.isUri = false,
    this.fileName,
    this.size,
  });

  @override
  String toString() {
    return 'PendingFile{isDirectory: $isDirectory, filePath: $filePath, fileName: $fileName, size: $size, directories: $directories}, isUri $isUri';
  }
}
