class StorageItem implements Comparable<StorageItem> {
  final String path;
  final String name;
  final bool isDir;
  final List<StorageItem> children;

  StorageItem({
    required this.path,
    required this.name,
    required this.isDir,
    required this.children,
  });

  @override
  int compareTo(StorageItem other) {
    if (this.isDir && !other.isDir) {
      return -1;
    } else if (!this.isDir && other.isDir) {
      return 1;
    } else {
      return this.name.toLowerCase().compareTo(other.name.toLowerCase());
    }
  }
}
