import 'dart:io';
import 'dart:typed_data';

import 'package:clipshare/app/data/models/exception_info.dart';
import 'package:clipshare/app/data/models/storage/s3_config.dart';
import 'package:clipshare/app/data/models/storage/storage_item.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:dart_aliyun_oss/dart_aliyun_oss.dart';
import 'package:dio/dio.dart';
import 'storage_client.dart';

///添加的Object大小不能超过 5 GB。
class AliyunOssClient extends StorageClient {
  static const tag = "AliyunOssClient";
  late final S3Config _config;
  late final OSSClient _client;
  final Uint8List _empty = Uint8List(0);

  String get _baseDir {
    return normalizeStorageBaseDir(_config.baseDir);
  }

  AliyunOssClient(S3Config config) {
    _config = config;
    _client = OSSClient.init(
      OSSConfig(
        endpoint: config.endPoint,
        region: config.region!,
        accessKeyIdProvider: () => config.accessKey,
        accessKeySecretProvider: () => config.secretKey,
        bucketName: config.bucketName,
        enableLogInterceptor: false,
      ),
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

  bool _responseIsOk(Response resp) {
    final status = resp.statusCode ?? 0;
    return status >= 200 && status < 300;
  }

  /// 将业务公开路径转换成带 baseDir 的 OSS object key。
  String _objectKey(String path, {bool isDirectory = false}) {
    return buildObjectStorageKey(path, baseDir: _baseDir, isDirectory: isDirectory);
  }

  /// 将 OSS 返回的 object key 转回公开路径，避免调用方再次带 baseDir 删除。
  String _publicPathFromObjectKey(String objectKey, {bool isDirectory = false}) {
    return publicPathFromObjectStorageKey(objectKey, baseDir: _baseDir, isDirectory: isDirectory);
  }

  @override
  Future<ExceptionInfo?> testConnect() async {
    try {
      StorageClient.recordClientInvoke('testConnect');
      await _client.listBucketResultV2(maxKeys: 1);
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
      final resp = await _client.putObjectFromBytes(_empty, dirPath);
      return _responseIsOk(resp);
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
      final resp = await _client.putObjectFromBytes(
        bytes,
        filePath,
        params: OSSRequestParams(onSendProgress: onProgress),
      );
      return _responseIsOk(resp);
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
      final resp = await _client.deleteObject(dirPath);
      return _responseIsOk(resp);
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
      final resp = await _client.deleteObject(filePath);
      return _responseIsOk(resp);
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
      final resp = (await _client.getObjectStream(
        filePath,
        params: OSSRequestParams(onReceiveProgress: onProgress),
      ));
      if (isLocalDir) {
        await Directory(localPath).create(recursive: true);
        localPath = normalizeStoragePath('$localPath/${path.split('/').last}');
      }
      final file = File(localPath);
      final writer = file.openWrite();
      await writer.addStream(resp.data!);
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
      final result = await _client.getObjectMeta(dirPath);
      return result != null && !result.isFile;
    } catch (err, stack) {
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
    final dirPath = _objectKey(path);
    try {
      StorageClient.recordClientInvoke('isFile', path: path);
      final result = await _client.getObjectMeta(dirPath);
      return result?.isFile ?? false;
    } catch (err, stack) {
      _logStorageError('isFile', err, stack, <String, Object?>{
        'path': path,
        'objectKey': dirPath,
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
    // OSS 目录列表必须以目录前缀查询；根路径则表示配置的 baseDir。
    final prefix = _objectKey(path, isDirectory: true);
    String? token;
    final items = <StorageItem>[];
    try {
      while (true) {
        StorageClient.recordClientInvoke('list', path: path);
        final resp = await _client.listBucketResultV2(
          prefix: prefix,
          startAfter: prefix,
          continuationToken: token,
        );
        final result = resp.data;
        if (result == null) {
          return [];
        }
        for (var dir in result.commonPrefixes) {
          late final List<StorageItem> children;
          final objectKey = dir.prefix!;
          final path = _publicPathFromObjectKey(objectKey, isDirectory: true);
          if (path.isEmpty) {
            continue;
          }
          if (recursive) {
            children = await list(path: path, recursive: true);
          } else {
            children = [];
          }
          items.add(
            StorageItem(
              path: path,
              name: removePathSuffix(path).split("/").last,
              isDir: true,
              children: recursive ? children : [],
            ),
          );
        }
        for (var file in result.contents) {
          final path = _publicPathFromObjectKey(file.key!);
          if (path.isEmpty) {
            continue;
          }
          items.add(
            StorageItem(
              path: path,
              name: path.split("/").last,
              isDir: false,
              children: [],
            ),
          );
        }
        if (result.isTruncated ?? false) {
          token = result.nextContinuationToken;
          continue;
        } else {
          break;
        }
      }
      items.sort();
      return items;
    } catch (err, stack) {
      _logStorageError('list', err, stack, <String, Object?>{
        'path': path,
        'recursive': recursive,
        'prefix': prefix,
      });
      return [];
    }
  }

  @override
  Future<List<String>> listRootDirectoryNames() async {
    String? token;
    final list = <String>[];
    try {
      while (true) {
        StorageClient.recordClientInvoke('listRootDirectoryNames');
        final resp = await _client.listBucketResultV2(continuationToken: token);
        final result = resp.data;
        if (result == null) {
          return [];
        }
        if (result.isTruncated ?? false) {
          token = result.nextContinuationToken;
          continue;
        }
        list.addAll(result.commonPrefixes.map((p) => p.prefix!));
        break;
      }
      return list;
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
      final resp = (await _client.getObject(
        filePath,
        params: OSSRequestParams(onReceiveProgress: onProgress),
      ));
      return resp.data;
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
      StorageClient.recordClientInvoke('uploadFile', path: path);
      final resp = await _client.putObject(
        File(localFilePath),
        filePath,
        params: OSSRequestParams(onSendProgress: onProgress),
      );
      return _responseIsOk(resp);
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
