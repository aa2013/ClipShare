import 'dart:typed_data';

import 'package:clipshare/app/data/models/exception_info.dart';
import 'package:clipshare/app/data/models/storage/storage_item.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/extensions/string_extension.dart';
import 'package:clipshare/app/utils/log.dart';

/// 存储操作进度回调函数类型
/// [count] 表示当前已处理的量（已传输的字节数）
/// [total] 表示需要处理的总量（文件总字节数）
typedef StorageProgressFunc = void Function(int count, int total);

/// 存储客户端抽象基类，定义了对不同存储后端（如 WebDAV, 对象存储）进行操作的通用接口
///
/// 具体实现只需要提供单级目录创建能力，逐级建目录策略由基类统一处理，
abstract class StorageClient {

  /// 底层存储客户端（WebDAV/S3/OSS）累计调用次数，进程内全局统计。
  static int _clientInvokeCount = 0;

  /// 记录一次底层存储客户端调用，并打印累计调用次数。
  static void recordClientInvoke() {
    _clientInvokeCount += 1;
    logger.info('StorageClient', 'Storage client invoke count: $_clientInvokeCount');
  }

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
  ///
  /// 会根据当前配置决定是直接创建目标目录，还是按层级逐级创建父目录。
  Future<bool> createDirectory(String path);

  /// 统一拼装存储错误日志的关键上下文，避免各个客户端重复手写格式。
  String formatStorageErrorDetails(String op, Map<String, Object?> details) {
    final parts = <String>['op=$op'];
    for (final entry in details.entries) {
      final value = entry.value;
      if (value == null) {
        continue;
      }
      parts.add('${entry.key}=$value');
    }
    return parts.join(', ');
  }

  /// 子类内部使用：去掉路径开头的 `/`，用于把公开路径转换为对象存储 key。
  String removePathPrefix(String path) {
    return path.replaceFirst(RegExp(r'^/+'), '');
  }

  /// 子类内部使用：去掉路径结尾的 `/`，避免文件路径误带目录后缀。
  String removePathSuffix(String path) {
    return path.replaceFirst(RegExp(r'/+$'), '');
  }

  /// 子类内部使用：保证目录路径以 `/` 结尾。
  String ensureDirectoryPathSuffix(String path) {
    if (path.isEmpty || path.endsWith(Constants.unixDirSeparate)) {
      return path;
    }
    return '$path${Constants.unixDirSeparate}';
  }

  /// 子类内部使用：统一归一化公开路径或对象存储 key。
  ///
  /// 这里会统一 Windows/Unix 分隔符、折叠重复 `/`、移除开头 `/`。
  /// 对象存储实现依赖该方法避免 baseDir 与业务路径拼接出 `//`。
  String normalizeStoragePath(String path, {bool keepTrailingSlash = false}) {
    var normalizedPath = path.unixPath.replaceAll(RegExp(r'/+'), '/');
    normalizedPath = removePathPrefix(normalizedPath);
    if (!keepTrailingSlash) {
      normalizedPath = removePathSuffix(normalizedPath);
    }
    return normalizedPath;
  }

  /// 子类内部使用：统一归一化对象存储 baseDir，并在非空时补齐尾部 `/`。
  String normalizeStorageBaseDir(String baseDir) {
    final normalizedBaseDir = normalizeStoragePath(baseDir);
    if (normalizedBaseDir.isEmpty) {
      return '';
    }
    return ensureDirectoryPathSuffix(normalizedBaseDir);
  }

  /// 子类内部使用：将公开业务路径转换成带 baseDir 的对象存储 key。
  String buildObjectStorageKey(
    String path, {
    required String baseDir,
    bool isDirectory = false,
  }) {
    final normalizedPath = normalizeStoragePath(path);
    var objectKey = '$baseDir$normalizedPath';
    objectKey = normalizeStoragePath(objectKey, keepTrailingSlash: isDirectory);
    if (isDirectory) {
      objectKey = ensureDirectoryPathSuffix(objectKey);
    }
    return objectKey;
  }

  /// 子类内部使用：将对象存储返回的 key 转回公开业务路径。
  String publicPathFromObjectStorageKey(
    String objectKey, {
    required String baseDir,
    bool isDirectory = false,
  }) {
    var publicPath = normalizeStoragePath(objectKey, keepTrailingSlash: isDirectory);
    final normalizedBaseDir = normalizeStoragePath(baseDir);
    if (normalizedBaseDir.isNotEmpty) {
      publicPath = publicPath.replaceFirst(RegExp('^${RegExp.escape(normalizedBaseDir)}(/|\$)'), '');
    }
    if (isDirectory) {
      publicPath = ensureDirectoryPathSuffix(publicPath);
    }
    return publicPath;
  }

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
