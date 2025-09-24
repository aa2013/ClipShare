import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:clipshare/app/data/models/exception_info.dart';
import 'package:clipshare/app/data/models/storage/s3_config.dart';
import 'package:clipshare/app/data/models/storage/storage_item.dart';
import 'package:clipshare/app/handlers/storage/storage_client.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/extensions/string_extension.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:minio/minio.dart';

class S3Client implements StorageClient {
  static const tag = "S3Client";
  late final S3Config _config;
  late final Minio _client;
  final Uint8List _empty = Uint8List(0);

  S3Client(S3Config config) {
    _config = config;
    _client = Minio(
      endPoint: config.endPoint,
      accessKey: config.accessKey,
      secretKey: config.secretKey,
      pathStyle: false,
    );
  }

  String _removePrefix(String str) {
    return str.replaceFirst(RegExp(r'^/+'), '');
  }

  String _removeSuffix(String str) {
    return str.replaceFirst(RegExp(r'/+$'), '');
  }

  @override
  Future<ExceptionInfo?> testConnect() async {
    try {
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
    var dirPath = _removePrefix(_config.baseDir + path);
    if (!dirPath.endsWith(Constants.unixDirSeparate)) {
      dirPath += Constants.unixDirSeparate;
    }
    try {
      await _client.putObject(_config.bucketName, dirPath, Stream<Uint8List>.value(_empty));
      return true;
    } catch (err, stack) {
      Log.error(tag, _config.toString() + err.toString(), stack);
      return false;
    }
  }

  @override
  Future<bool> createFile(String path, Uint8List bytes, {StorageProgressFunc? onProgress, bool createDir = false}) async {
    var filePath = _removePrefix(_config.baseDir + path);
    filePath = _removeSuffix(filePath);
    try {
      await _client.putObject(_config.bucketName, filePath, Stream<Uint8List>.value(bytes));
      return true;
    } catch (err, stack) {
      Log.error(tag, _config.toString() + err.toString(), stack);
      return false;
    }
  }

  @override
  Future<bool> deleteDirectory(String path) async {
    var dirPath = _removePrefix(_config.baseDir + path);
    if (!dirPath.endsWith(Constants.unixDirSeparate)) {
      dirPath += Constants.unixDirSeparate;
    }
    try {
      await _client.removeObject(_config.bucketName, dirPath);
      return true;
    } catch (err, stack) {
      Log.error(tag, _config.toString() + err.toString(), stack);
      return false;
    }
  }

  @override
  Future<bool> deleteFile(String path) async {
    var filePath = _removePrefix(_config.baseDir + path);
    filePath = _removeSuffix(filePath);
    try {
      await _client.removeObject(_config.bucketName, filePath);
      return true;
    } catch (err, stack) {
      Log.error(tag, _config.toString() + err.toString(), stack);
      return false;
    }
  }

  @override
  Future<bool> downloadFile(String path, String localPath, {StorageProgressFunc? onProgress, bool isLocalDir = false}) async {
    path = _removeSuffix(path.unixPath);
    try {
      var filePath = _removePrefix(_config.baseDir + path);
      final props = await _client.statObject(_config.bucketName, filePath);
      final totalSize = props.size!;
      var count = 0;
      final stream = (await _client.getObject(_config.bucketName, filePath)).transform(
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
      return true;
    } catch (err, stack) {
      Log.error(tag, _config.toString() + err.toString(), stack);
      return false;
    }
  }

  @override
  Future<bool> isDirectory(String path) async {
    path = path.unixPath;
    try {
      var dirPath = _removePrefix(_config.baseDir + path);
      if (!dirPath.endsWith(Constants.unixDirSeparate)) {
        dirPath += Constants.unixDirSeparate;
      }
      final result = await _client.statObject(_config.bucketName, dirPath);
      return result.size == 0;
    } catch (err, stack) {
      Log.error(tag, _config.toString() + err.toString(), stack);
      return false;
    }
  }

  @override
  Future<bool> isFile(String path) async {
    path = path.unixPath;
    try {
      var filePath = _removePrefix(_config.baseDir + path);
      filePath = _removeSuffix(filePath);
      final result = await _client.statObject(_config.bucketName, filePath);
      return (result.size ?? 0) > 0;
    } catch (err, stack) {
      Log.error(tag, _config.toString() + err.toString(), stack);
      return false;
    }
  }

  @override
  Future<List<StorageItem>> list({String path = "", bool recursive = false}) async {
    var dirPath = _removePrefix(_config.baseDir + path);
    if (dirPath != '' && !dirPath.endsWith("/")) {
      dirPath += "/";
    }
    List<StorageItem> result = [];
    try {
      final items = await _client.listAllObjectsV2(_config.bucketName, prefix: dirPath);
      for (var item in items.prefixes) {
        late List<StorageItem> children;
        if (recursive) {
          children = await list(path: item, recursive: true);
        } else {
          children = [];
        }
        result.add(
          StorageItem(
            path: item,
            name: _removeSuffix(item).split("/").last,
            isDir: true,
            children: children,
          ),
        );
      }
      for (var item in items.objects) {
        if (item.key?.endsWith("/") ?? true) {
          continue;
        }
        result.add(
          StorageItem(
            path: item.key!,
            name: item.key!.split("/").last,
            isDir: false,
            children: [],
          ),
        );
      }
      result.sort();
      return result;
    } catch (err, stack) {
      Log.error(tag, _config.toString() + err.toString(), stack);
      return [];
    }
  }

  @override
  Future<List<String>> listRootDirectoryNames() async {
    try {
      final result = await _client.listAllObjectsV2(_config.bucketName);
      return result.prefixes;
    } catch (err, stack) {
      Log.error(tag, _config.toString() + err.toString(), stack);
      return [];
    }
  }

  @override
  Future<List<int>?> readFileBytes(String path, {StorageProgressFunc? onProgress}) async {
    path = _removeSuffix(path.unixPath);
    try {
      var filePath = _removePrefix(_config.baseDir + path);
      final stream = (await _client.getObject(_config.bucketName, filePath));
      final List<int> result = [];
      await for (final chunk in stream) {
        result.addAll(chunk); // 将每个数据块合并到结果列表
      }
      return result;
    } catch (err, stack) {
      Log.error(tag, _config.toString() + err.toString(), stack);
      return null;
    }
  }

  @override
  Future<bool> uploadFile(String path, String localFilePath, {StorageProgressFunc? onProgress}) async {
    var filePath = _removePrefix(_config.baseDir + path);
    filePath = _removeSuffix(filePath);
    try {
      final file = File(localFilePath);
      final totalSize = await file.length();
      final reader = file.openRead().map((chunk) => Uint8List.fromList(chunk));
      await _client.putObject(_config.bucketName, filePath, reader, size: totalSize, onProgress: (count) => onProgress?.call(count, totalSize));
      return true;
    } catch (err, stack) {
      Log.error(tag, _config.toString() + err.toString(), stack);
      return false;
    }
  }
}
