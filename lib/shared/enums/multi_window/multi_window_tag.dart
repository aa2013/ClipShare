/// 桌面多窗口类型标记。
enum MultiWindowTag {
  history,
  devices;

  /// 按名称解析窗口标记；未知名称抛出异常。
  static MultiWindowTag getValue(String name) => MultiWindowTag.values.firstWhere(
        (e) => e.name == name,
        orElse: () {
          throw Exception('Unknown Tag $name');
        },
      );
}
