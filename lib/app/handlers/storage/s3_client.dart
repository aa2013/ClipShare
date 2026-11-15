import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:clipshare/app/data/models/exception_info.dart';
import 'package:clipshare/app/data/models/storage/s3_config.dart';
import 'package:clipshare/app/data/models/storage/storage_item.dart';
import 'package:clipshare/app/handlers/storage/storage_client.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:minio/minio.dart';

class S3Client extends StorageClient {
  static const tag = "S3Client";
  late final S3Config _config;
  late final Minio _client;
  final Uint8List _empty = Uint8List(0);

  String get _baseDir {
    return normalizeStorageBaseDir(_config.baseDir);
  }

  S3Client(S3Config config) {
    _config = config;
    _client = Minio(
      endPoint: config.endPoint,
      accessKey: config.accessKey,
      secretKey: config.secretKey,
      region: config.region,
      pathStyle: config.pathStyle,
      userAgent: config.userAgent,
    );
  }

  void _logStorageError(
    String op,
    Object err,
    StackTrace stack,
    Map<String, Object?> details,
  ) {
    final message = '${_config.toString()} ${formatStorageErrorDetails(op, details)}, err=$err';
    logger.error(tag, message, stack);
  }

  /// 将业务公开路径转换成带 baseDir 的 S3 object key。
  String _objectKey(String path, {bool isDirectory = false}) {
    return buildObjectStorageKey(path, baseDir: _baseDir, isDirectory: isDirectory);
  }

  /// 将 S3 返回的 object key 转回公开路径，避免调用方再次带 baseDir。
  String _publicPathFromObjectKey(String objectKey, {bool isDirectory = false}) {
    return publicPathFromObjectStorageKey(objectKey, baseDir: _baseDir, isDirectory: isDirectory);
  }

  @override
  Future<ExceptionInfo?> testConnect() async {
    try {
      StorageClient.recordClientInvoke('testConnect');
      final result = await _client.bucketExists(_config.bucketName);
      if (!result) {
        throw 'Bucket Not Found';
      }
      return null;
    } catch (err, stack) {
      return ExceptionInfo(err: err, stackTrace: stack);
    }
  }

  @override
  Future<bool> createDirectory(String path) async {
    final dirPath = _objectKey(path, isDirectory: true);
    try {
      StorageClient.recordClientInvoke('createDirectory', path: path);
      await _client.putObject(
        _config.bucketName,
        dirPath,
        Stream<Uint8List>.value(_empty),
      );
      return true;
    } catch (err, stack) {
      _logStorageError('createDirectoryDirect', err, stack, <String, Object?>{
        'path': path,
        'objectKey': dirPath,
      });
      return false;
    }
  }

  @override
  Future<bool> createFile(
    String path,
    Uint8List bytes, {
    StorageProgressFunc? onProgress,
    bool createDir = false,
  }) async {
    path = normalizeStoragePath(path);
    final filePath = _objectKey(path);
    try {
      StorageClient.recordClientInvoke('createFile', path: path);
      await _client.putObject(
        _config.bucketName,
        filePath,
        Stream<Uint8List>.value(bytes),
      );
      return true;
    } catch (err, stack) {
      _logStorageError('createFile', err, stack, <String, Object?>{
        'path': path,
        'objectKey': filePath,
        'bytesLength': bytes.length,
        'createDir': createDir,
      });
      return false;
    }
  }

  @override
  Future<bool> deleteDirectory(String path) async {
    final dirPath = _objectKey(path, isDirectory: true);
    try {
      StorageClient.recordClientInvoke('deleteDirectory', path: path);
      await _client.removeObject(_config.bucketName, dirPath);
      return true;
    } catch (err, stack) {
      _logStorageError('deleteDirectory', err, stack, <String, Object?>{
        'path': path,
        'objectKey': dirPath,
      });
      return false;
    }
  }

  @override
  Future<bool> deleteFile(String path) async {
    path = normalizeStoragePath(path);
    final filePath = _objectKey(path);
    try {
      StorageClient.recordClientInvoke('deleteFile', path: path);
      await _client.removeObject(_config.bucketName, filePath);
      return true;
    } catch (err, stack) {
      _logStorageError('deleteFile', err, stack, <String, Object?>{
        'path': path,
        'objectKey': filePath,
      });
      return false;
    }
  }

  @override
  Future<bool> downloadFile(
    String path,
    String localPath, {
    StorageProgressFunc? onProgress,
    bool isLocalDir = false,
  }) async {
    path = normalizeStoragePath(path);
    final filePath = _objectKey(path);
    try {
      StorageClient.recordClientInvoke('downloadFile', path: path);
      final props = await _client.statObject(_config.bucketName, filePath);
      final totalSize = props.size!;
      var count = 0;
      StorageClient.recordClientInvoke('downloadFile', path: path);
      final stream = (await _client.getObject(_config.bucketName, filePath))
          .transform(
            StreamTransformer<List<int>, List<int>>.fromHandlers(
              handleData: (dataChunk, sink) {
                count += dataChunk.length;
                onProgress?.call(count, totalSize);
                sink.add(dataChunk);
              },
            ),
          );
      if (isLocalDir) {
        await Directory(localPath).create(recursive: true);
        if (!localPath.endsWith("/")) {
          localPath += "/";
        }
        localPath += path.split("/").last;
      }
      final file = File(localPath);
      final writer = file.openWrite();
      await writer.addStream(stream);
      await writer.close();
      return true;
    } catch (err, stack) {
      _logStorageError('downloadFile', err, stack, <String, Object?>{
        'path': path,
        'localPath': localPath,
        'isLocalDir': isLocalDir,
      });
      return false;
    }
  }

  @override
  Future<bool> isDirectory(String path) async {
    path = normalizeStoragePath(path);
    final dirPath = _objectKey(path, isDirectory: true);
    try {
      StorageClient.recordClientInvoke('isDirectory', path: path);
      final result = await _client.statObject(_config.bucketName, dirPath);
      return result.size == 0;
    } catch (err, stack) {
      try {
        // qiniu S3 对空目录 marker 的 HEAD 兼容性不稳定，使用前缀列表兜底确认目录存在。
        StorageClient.recordClientInvoke('isDirectory', path: path);
        final items = await _client.listAllObjectsV2(_config.bucketName, prefix: dirPath);
        final hasDirectoryMarker = items.objects.any((item) => item.key == dirPath);
        final hasChildren = items.objects.any((item) => item.key?.startsWith(dirPath) ?? false) ||
            items.prefixes.any((prefix) => prefix.startsWith(dirPath));
        if (hasDirectoryMarker || hasChildren) {
          return true;
        }
      } catch (_) {
        // 兜底检查失败时继续记录原始 HEAD 错误，方便定位真实服务端异常。
      }
      _logStorageError('isDirectory', err, stack, <String, Object?>{
        'path': path,
        'objectKey': dirPath,
      });
      return false;
    }
  }

  @override
  Future<bool> isFile(String path) async {
    path = normalizeStoragePath(path);
    final filePath = _objectKey(path);
    try {
      StorageClient.recordClientInvoke('isFile', path: path);
      final result = await _client.statObject(_config.bucketName, filePath);
      return (result.size ?? 0) > 0;
    } catch (err, stack) {
      _logStorageError('isFile', err, stack, <String, Object?>{
        'path': path,
        'objectKey': filePath,
      });
      return false;
    }
  }

  @override
  Future<List<StorageItem>> list({
    String path = "",
    bool recursive = false,
  }) async {
    path = normalizeStoragePath(path);
    final dirPath = _objectKey(path, isDirectory: true);
    List<StorageItem> result = [];
    try {
      StorageClient.recordClientInvoke('list', path: path);
      final items = await _client.listAllObjectsV2(
        _config.bucketName,
        prefix: dirPath,
      );
      for (var item in items.prefixes) {
        late List<StorageItem> children;
        final path = _publicPathFromObjectKey(item, isDirectory: true);
        if (path.isEmpty) {
          continue;
        }
        if (recursive) {
          children = await list(path: path, recursive: true);
        } else {
          children = [];
        }
        result.add(
          StorageItem(
            path: path,
            name: removePathSuffix(path).split("/").last,
            isDir: true,
            children: children,
          ),
        );
      }
      for (var item in items.objects) {
        if (item.key?.endsWith("/") ?? true) {
          continue;
        }
        final path = _publicPathFromObjectKey(item.key!);
        if (path.isEmpty) {
          continue;
        }
        result.add(
          StorageItem(
            path: path,
            name: path.split("/").last,
            isDir: false,
            children: [],
          ),
        );
      }
      result.sort();
      return result;
    } catch (err, stack) {
      _logStorageError('list', err, stack, <String, Object?>{
        'path': path,
        'recursive': recursive,
        'objectKey': dirPath,
      });
      return [];
    }
  }

  @override
  Future<List<String>> listRootDirectoryNames() async {
    try {
      StorageClient.recordClientInvoke('listRootDirectoryNames');
      final result = await _client.listAllObjectsV2(_config.bucketName);
      return result.prefixes;
    } catch (err, stack) {
      _logStorageError('listRootDirectoryNames', err, stack, <String, Object?>{
        'baseDir': _baseDir,
      });
      return [];
    }
  }

  @override
  Future<List<int>?> readFileBytes(
    String path, {
    StorageProgressFunc? onProgress,
  }) async {
    path = normalizeStoragePath(path);
    final filePath = _objectKey(path);
    try {
      StorageClient.recordClientInvoke('readFileBytes', path: path);
      final stream = (await _client.getObject(_config.bucketName, filePath));
      final List<int> result = [];
      await for (final chunk in stream) {
        result.addAll(chunk); // 将每个数据块合并到结果列表
      }
      return result;
    } catch (err, stack) {
      _logStorageError('readFileBytes', err, stack, <String, Object?>{
        'path': path,
        'objectKey': filePath,
      });
      return null;
    }
  }

  @override
  Future<bool> uploadFile(
    String path,
    String localFilePath, {
    StorageProgressFunc? onProgress,
    bool createDir = false,
  }) async {
    path = normalizeStoragePath(path);
    final filePath = _objectKey(path);
    try {
      final file = File(localFilePath);
      final totalSize = await file.length();
      final reader = file.openRead().map((chunk) => Uint8List.fromList(chunk));
      StorageClient.recordClientInvoke('uploadFile', path: path);
      await _client.putObject(
        _config.bucketName,
        filePath,
        reader,
        size: totalSize,
        onProgress: (count) => onProgress?.call(count, totalSize),
      );
      return true;
    } catch (err, stack) {
      _logStorageError('uploadFile', err, stack, <String, Object?>{
        'path': path,
        'localFilePath': localFilePath,
        'objectKey': filePath,
      });
      return false;
    }
  }
}
