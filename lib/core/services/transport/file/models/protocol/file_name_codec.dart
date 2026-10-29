/// 协议文件名编解码：目录层级以 "/" 拼进文件名随控制消息传输，
/// 接收端据此还原目录结构与展示分组。
library;

/// 将相对目录层级与文件名拼为协议文件名（"dir/sub/name.ext"）
String buildProtocolFileName(List<String> relativeDirs, String fileName) {
  if (relativeDirs.isEmpty) {
    return fileName;
  }
  return '${relativeDirs.join('/')}/$fileName';
}

/// 提取协议文件名的顶层目录分组键，无目录层级时返回 null
String? parseProtocolFileGroupKey(String fileName) {
  final index = fileName.indexOf('/');
  if (index <= 0) {
    return null;
  }
  return fileName.substring(0, index);
}
