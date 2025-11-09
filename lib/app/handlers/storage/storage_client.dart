import 'dart:typed_data';

import 'package:clipshare/app/data/models/exception_info.dart';
import 'package:clipshare/app/data/models/storage/storage_item.dart';

/// 存储操作进度回调函数类型
/// [count] 表示当前已处理的量（已传输的字节数）
/// [total] 表示需要处理的总量（文件总字节数）
typedef StorageProgressFunc = void Function(int count, int total);

/// 存储客户端抽象基类，定义了对不同存储后端（如 WebDav, 对象存储）进行操作的通用接口
abstract class StorageClient {
  /// 测试连接
  Future<ExceptionInfo?> testConnect();

  /// 获取根目录下的所有文件夹名称列表
  Future<List<String>> listRootDirectoryNames();

  /// 列出指定路径下的内容
  ///
  /// [path] - 要列出的目录路径（默认为根目录）
  /// [recursive] - 是否递归列出子目录内容（默认为false）
  Future<List<StorageItem>> list({String path = "", bool recursive = false});

  /// 检查指定路径是否为目录
  Future<bool> isDirectory(String path);

  /// 创建目录
  Future<bool> createDirectory(String path);

  /// 删除目录
  Future<bool> deleteDirectory(String path);

  /// 检查指定路径是否为文件
  Future<bool> isFile(String path);

  /// 创建文件
  ///
  /// [path] - 文件路径
  /// [bytes] - 文件内容字节数组
  /// [onProgress] - 可选进度回调
  /// [createDir] - 如果父目录不存在是否自动创建（默认为false），对象存储忽略该字段
  Future<bool> createFile(
    String path,
    Uint8List bytes, {
    StorageProgressFunc? onProgress,
    bool createDir = false,
  });

  /// 上传本地文件到指定路径
  ///
  /// [path] - 目标存储路径
  /// [localFilePath] - 本地文件路径
  /// [onProgress] - 可选进度回调
  Future<bool> uploadFile(
    String path,
    String localFilePath, {
    StorageProgressFunc? onProgress,
  });

  /// 下载文件到本地
  ///
  /// [path] - 源文件存储路径
  /// [localPath] - 本地目标路径
  /// [onProgress] - 可选进度回调
  /// [isLocalDir] - 本地路径是否为目录（默认为false）
  Future<bool> downloadFile(
    String path,
    String localPath, {
    StorageProgressFunc? onProgress,
    bool isLocalDir = false,
  });

  /// 读取文件内容为字节数组
  ///
  /// [path] - 文件路径
  /// [onProgress] - 可选进度回调
  Future<List<int>?> readFileBytes(
    String path, {
    StorageProgressFunc? onProgress,
  });

  /// 删除文件
  Future<bool> deleteFile(String path);
}
