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
    StorageClient.recordClientInvoke('readResource', path: path);
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
      StorageClient.recordClientInvoke('testConnect');
      await _client.listWithDepth(Constants.unixDirSeparate, 0);
      return null;
    } catch (err, stack) {
      return ExceptionInfo(err: err, stackTrace: stack);
    }
  }

  @override
  Future<List<String>> listRootDirectoryNames() async {
    try {
      StorageClient.recordClientInvoke('listRootDirectoryNames');
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
    final result = <StorageItem>[];
    StorageClient.recordClientInvoke('list', path: path);
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

  /// 先尝试直接创建目标目录，失败后再逐级补齐父目录。
  ///
  /// [path] 为公开存储路径。直接创建失败时不区分具体错误类型，
  /// 统一回退到级联创建，以兼容不支持递归创建目录的 WebDAV 服务端。
  @override
  Future<bool> createDirectory(String path) async {
    final normalizedPath = path.unixPath;
    if (normalizedPath.isEmpty || normalizedPath == Constants.unixDirSeparate) {
      return true;
    }
    try {
      await _createDirectoryRequest(normalizedPath);
      return true;
    } catch (_) {
      // 目标已存在时 WebDAV 常返回 MKCOL 失败，先确认目标目录可用再决定是否级联。
      if (await _directoryExistsSilently(normalizedPath)) {
        return true;
      }
      // 目标目录可能因父目录缺失而创建失败，交给级联逻辑补齐路径后重试。
    }
    return _createDirectoryCascade(normalizedPath);
  }

  /// 逐级创建每一层目录，兼容不支持递归建目录的服务端。
  ///
  /// [path] 为已经归一化的公开存储路径。
  Future<bool> _createDirectoryCascade(String path) async {
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

  /// 直接向 WebDAV 服务端发送一次 MKCOL 请求。
  ///
  /// [path] 为公开存储路径，调用方负责决定失败后的回退策略。
  Future<void> _createDirectoryRequest(String path) async {
    final normalizedPath = path.unixPath;
    final dirPath = _toClientPath(normalizedPath, isDirectory: true);
    StorageClient.recordClientInvoke('createDirectory', path: normalizedPath);
    await _client.createDirectory(dirPath);
  }

  Future<bool> _createDirectoryDirect(String path) async {
    path = path.unixPath;
    final dirPath = _toClientPath(path, isDirectory: true);
    try {
      await _createDirectoryRequest(path);
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
      StorageClient.recordClientInvoke('deleteDirectory', path: path);
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

  /// 先直接写入文件，失败后按需级联创建父目录并重试一次。
  ///
  /// [createDir] 为 true 时启用失败回退；首次失败不立即记录错误，
  /// 只有级联失败或重试失败时才将最终错误写入日志。
  @override
  Future<bool> createFile(
    String path,
    Uint8List bytes, {
    StorageProgressFunc? onProgress,
    bool createDir = false,
  }) async {
    path = path.unixPath;
    final filePath = _toClientPath(path, isDirectory: false);
    Object? firstError;
    try {
      await _createFileRequest(path, filePath, bytes);
      onProgress?.call(bytes.length, bytes.length);
      return true;
    } catch (err, stack) {
      firstError = err;
      if (createDir) {
        final dir = (path.split(Constants.unixDirSeparate)..removeLast())
            .join(Constants.unixDirSeparate);
        final directoryCreated = await createDirectory(dir);
        if (directoryCreated) {
          try {
            await _createFileRequest(path, filePath, bytes);
            onProgress?.call(bytes.length, bytes.length);
            return true;
          } catch (retryErr, retryStack) {
            _logStorageError('createFile', retryErr, retryStack, <String, Object?>{
              'path': path,
              'clientPath': filePath,
              'bytesLength': bytes.length,
              'createDir': createDir,
              'firstError': firstError,
            });
            return false;
          }
        }
      }
      _logStorageError('createFile', err, stack, <String, Object?>{
        'path': path,
        'clientPath': filePath,
        'bytesLength': bytes.length,
        'createDir': createDir,
        'fallback': createDir ? 'createDirectory' : null,
      });
      return false;
    }
  }

  /// 直接向 WebDAV 服务端发送一次文件写入请求。
  ///
  /// [path] 为公开存储路径，[filePath] 为已转换的客户端路径。
  Future<void> _createFileRequest(
    String path,
    String filePath,
    Uint8List bytes,
  ) async {
    StorageClient.recordClientInvoke('createFile', path: path);
    await _client.putStream(
      filePath,
      Stream<List<int>>.value(bytes),
      bytes.length,
      "application/octet-stream",
    );
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
      StorageClient.recordClientInvoke('uploadFile', path: path);
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
      StorageClient.recordClientInvoke('downloadFile', path: path);
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
      // WebDAV GET 失败即可表达文件不存在或不可读，避免读取前额外探测文件类型。
      StorageClient.recordClientInvoke('readFileBytes', path: path);
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
      StorageClient.recordClientInvoke('deleteFile', path: path);
      await _client.delete(_toClientPath(path, isDirectory: false));
      return true;
    } catch (err, stack) {
      _logStorageError('deleteFile', err, stack, <String, Object?>{'path': path});
      return false;
    }
  }

  //endregion
}
