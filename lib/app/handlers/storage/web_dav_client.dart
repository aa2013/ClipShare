import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:clipshare/app/data/models/exception_info.dart';
import 'package:clipshare/app/data/models/storage/storage_item.dart';
import 'package:clipshare/app/data/models/storage/web_dav_config.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/extensions/string_extension.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:webdav_plus/webdav_plus.dart';

import 'storage_client.dart';

class WebDAVClient extends StorageClient {
  final WebDAVConfig _config;
  late WebdavClient _client;
  static const tag = "WebDAVClient";

  String get _baseDir {
    if (_config.baseDir.endsWith("/")) {
      return _config.baseDir;
    }
    return "${_config.baseDir}/";
  }

  String get _serverPathPrefix {
    final serverPath = Uri.tryParse(_config.server)?.path.unixPath ?? "";
    if (serverPath.isEmpty || serverPath == Constants.unixDirSeparate) {
      return "";
    }
    return removePathSuffix(serverPath);
  }

  WebDAVClient(this._config) {
    _client = WebdavClient.withCredentials(
      _config.username,
      _config.password,
      baseUrl: _config.server,
      // webdav_plus only keeps upload progress when using streaming uploads,
      // and those uploads must authenticate preemptively because streams cannot be replayed after a 401.
      isPreemptive: true,
      userAgent: _config.userAgent,
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

  String _stripServerPathPrefix(String path) {
    var normalizedPath = path.unixPath;
    final serverPathPrefix = _serverPathPrefix;
    // DavResource.path contains the path part of the configured server URL,
    // so strip it to keep exposing storage paths instead of `/remote.php/...`.
    if (serverPathPrefix.isNotEmpty && normalizedPath.startsWith(serverPathPrefix)) {
      normalizedPath = normalizedPath.substring(serverPathPrefix.length);
      if (normalizedPath.isEmpty) {
        return Constants.unixDirSeparate;
      }
    }
    return normalizedPath;
  }

  String _toClientPath(String path, {bool isDirectory = false}) {
    var normalizedPath = _stripServerPathPrefix(path);
    final baseDir = _baseDir.unixPath;
    final baseDirWithoutSuffix = removePathSuffix(baseDir);
    if (normalizedPath.isEmpty || normalizedPath == Constants.unixDirSeparate) {
      normalizedPath = baseDir;
    } else if (normalizedPath == baseDirWithoutSuffix || normalizedPath == baseDir) {
      normalizedPath = baseDir;
    } else if (!normalizedPath.startsWith(baseDir)) {
      normalizedPath = (baseDir + normalizedPath).unixPath;
    }
    return isDirectory ? ensureDirectoryPathSuffix(normalizedPath) : removePathSuffix(normalizedPath);
  }

  String _toStoragePath(String path, {required bool isDirectory}) {
    var normalizedPath = _stripServerPathPrefix(path);
    if (normalizedPath.isEmpty) {
      normalizedPath = Constants.unixDirSeparate;
    } else if (!normalizedPath.startsWith(Constants.unixDirSeparate)) {
      normalizedPath = "${Constants.unixDirSeparate}$normalizedPath";
    }
    if (normalizedPath == Constants.unixDirSeparate) {
      return normalizedPath;
    }
    return isDirectory ? ensureDirectoryPathSuffix(normalizedPath) : removePathSuffix(normalizedPath);
  }

  List<DavResource> _skipSelfResource(List<DavResource> resources) {
    if (resources.isEmpty) {
      return const [];
    }
    // Per RFC 4918 and webdav_plus docs, directory listing returns the requested collection as the first item.
    return resources.length == 1 ? const [] : resources.sublist(1);
  }

  Future<DavResource?> _readResource(String path, {required bool isDirectory}) async {
    StorageClient.recordClientInvoke();
    final resources = await _client.listWithDepth(
      _toClientPath(path, isDirectory: isDirectory),
      0,
    );
    if (resources.isEmpty) {
      return null;
    }
    return resources.first;
  }

  Future<bool> _directoryExistsSilently(String path) async {
    try {
      // 某些 WebDAV 服务端会对已存在目录返回 MKCOL 405，所以失败后再静默确认一次。
      final resource = await _readResource(path, isDirectory: true);
      return resource?.isDirectory == true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<ExceptionInfo?> testConnect() async {
    try {
      StorageClient.recordClientInvoke();
      await _client.listWithDepth(Constants.unixDirSeparate, 0);
      return null;
    } catch (err, stack) {
      return ExceptionInfo(err: err, stackTrace: stack);
    }
  }

  @override
  Future<List<String>> listRootDirectoryNames() async {
    try {
      StorageClient.recordClientInvoke();
      final resources = await _client.list(_toClientPath("", isDirectory: true));
      final items = _skipSelfResource(resources);
      return items
        .where((item) => item.isDirectory && item.name.isNotEmpty)
        .map((item) => _toStoragePath(item.path, isDirectory: true))
        .toList()
        ..sort();
    } catch (err, stack) {
      _logStorageError('listRootDirectoryNames', err, stack, <String, Object?>{
        'baseDir': _baseDir,
      });
      return [];
    }
  }

  @override
  Future<List<StorageItem>> list({String path = "", bool recursive = false}) async {
    path = path.unixPath;
    final dirPath = _toClientPath(path, isDirectory: true);
    if (!await isDirectory(path)) {
      throw '$path is not directory!';
    }
    final result = <StorageItem>[];
    StorageClient.recordClientInvoke();
    final resources = await _client.list(dirPath);
    final items = _skipSelfResource(resources);
    for (final item in items) {
      final itemPath = _toStoragePath(item.path, isDirectory: item.isDirectory);
      late final List<StorageItem> children;
      if (recursive && item.isDirectory) {
        children = await list(path: itemPath, recursive: true);
      } else {
        children = const [];
      }
      result.add(
        StorageItem(
          path: itemPath,
          name: item.name,
          isDir: item.isDirectory,
          children: children,
        ),
      );
    }
    result.sort();
    return result;
  }

  //region Directory

  @override
  Future<bool> isDirectory(String path) async {
    path = path.unixPath;
    try {
      final resource = await _readResource(path, isDirectory: true);
      return resource?.isDirectory == true;
    } catch (err, stack) {
      _logStorageError('isDirectory', err, stack, <String, Object?>{'path': path});
      return false;
    }
  }

  /// 逐级创建每一层目录，兼容不支持递归建目录的服务端
  @override
  Future<bool> createDirectory(String path) async {
    final normalizedPath = path.unixPath;
    final segments = normalizedPath.split('/').where((segment) => segment.isNotEmpty);
    final isAbsolutePath = normalizedPath.startsWith('/');
    var currentPath = '';
    for (final segment in segments) {
      if (currentPath.isEmpty) {
        currentPath = isAbsolutePath ? '/$segment' : segment;
      } else {
        currentPath = '$currentPath/$segment';
      }
      if (!await _createDirectoryDirect(currentPath)) {
        return false;
      }
    }
    return true;
  }


  Future<bool> _createDirectoryDirect(String path) async {
    path = path.unixPath;
    final dirPath = _toClientPath(path, isDirectory: true);
    try {
      StorageClient.recordClientInvoke();
      await _client.createDirectory(dirPath);
      return true;
    } catch (err, stack) {
      if (await _directoryExistsSilently(path)) {
        return true;
      }
      _logStorageError('createDirectoryDirect', err, stack, <String, Object?>{
        'path': path,
        'clientPath': dirPath,
      });
      return false;
    }
  }

  @override
  Future<bool> deleteDirectory(String path) async {
    try {
      path = path.unixPath;
      final isDir = await isDirectory(path);
      if (!isDir) {
        return false;
      }
      StorageClient.recordClientInvoke();
      await _client.delete(_toClientPath(path, isDirectory: true));
      return true;
    } catch (err, stack) {
      _logStorageError('deleteDirectory', err, stack, <String, Object?>{'path': path});
      return false;
    }
  }

  //endregion

  //region File

  @override
  Future<bool> isFile(String path) async {
    path = path.unixPath;
    try {
      final resource = await _readResource(path, isDirectory: false);
      return resource?.isFile == true;
    } catch (err, stack) {
      _logStorageError('isFile', err, stack, <String, Object?>{'path': path});
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
    path = path.unixPath;
    final filePath = _toClientPath(path, isDirectory: false);
    try {
      if (createDir) {
        final dir = (path.split(Constants.unixDirSeparate)..removeLast())
            .join(Constants.unixDirSeparate);
        final result = await createDirectory(dir);
        if (!result) {
          return false;
        }
      }
      StorageClient.recordClientInvoke();
      await _client.putStream(
        filePath,
        Stream<List<int>>.value(bytes),
        bytes.length,
        "application/octet-stream",
      );
      onProgress?.call(bytes.length, bytes.length);
      return true;
    } catch (err, stack) {
      _logStorageError('createFile', err, stack, <String, Object?>{
        'path': path,
        'clientPath': filePath,
        'bytesLength': bytes.length,
        'createDir': createDir,
      });
      return false;
    }
  }

  @override
  Future<bool> uploadFile(
    String path,
    String localFilePath, {
    StorageProgressFunc? onProgress,
  }) async {
    path = path.unixPath;
    try {
      final file = File(localFilePath);
      if (!await file.exists()) {
        return false;
      }
      final filePath = _toClientPath(path, isDirectory: false);
      StorageClient.recordClientInvoke();
      await _client.putFileStream(filePath, file, onProgress: onProgress);
      return true;
    } catch (err, stack) {
      _logStorageError('uploadFile', err, stack, <String, Object?>{
        'path': path,
        'localFilePath': localFilePath,
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
    path = path.unixPath;
    try {
      final filePath = _toClientPath(path, isDirectory: false);
      if (!await isFile(path)) {
        return false;
      }
      final resource = await _readResource(path, isDirectory: false);
      if (resource == null) {
        return false;
      }
      Directory localDir;
      if (!isLocalDir) {
        localDir = File(localPath).parent;
      } else {
        localDir = Directory(localPath);
        localPath = localDir.uri.resolve(resource.name).toFilePath();
      }
      await localDir.create(recursive: true);
      StorageClient.recordClientInvoke();
      await _client.downloadToFile(filePath, localPath, onProgress: onProgress);
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
  Future<List<int>?> readFileBytes(
    String path, {
    StorageProgressFunc? onProgress,
  }) async {
    path = path.unixPath;
    try {
      if (!await isFile(path)) {
        return null;
      }
      StorageClient.recordClientInvoke();
      final bytes = await _client.get(_toClientPath(path, isDirectory: false));
      onProgress?.call(bytes.length, bytes.length);
      return bytes;
    } catch (err, stack) {
      _logStorageError('readFileBytes', err, stack, <String, Object?>{'path': path});
      return null;
    }
  }

  @override
  Future<bool> deleteFile(String path) async {
    try {
      path = path.unixPath;
      final isFile = await this.isFile(path);
      if (!isFile) {
        return false;
      }
      StorageClient.recordClientInvoke();
      await _client.delete(_toClientPath(path, isDirectory: false));
      return true;
    } catch (err, stack) {
      _logStorageError('deleteFile', err, stack, <String, Object?>{'path': path});
      return false;
    }
  }

  //endregion
}
