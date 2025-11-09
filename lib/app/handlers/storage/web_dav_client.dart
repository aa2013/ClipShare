import 'dart:io';
import 'dart:typed_data';

import 'package:clipshare/app/data/models/exception_info.dart';
import 'package:clipshare/app/data/models/storage/storage_item.dart';
import 'package:clipshare/app/data/models/storage/web_dav_config.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/extensions/string_extension.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:webdav_client/webdav_client.dart' as webdav;

import 'storage_client.dart';

class WebDavClient implements StorageClient {
  final WebDavConfig _config;
  late webdav.Client _client;
  static const tag = "WebDavClient";

  String get _baseDir {
    if (_config.baseDir.endsWith("/")) {
      return _config.baseDir;
    }
    return "${_config.baseDir}/";
  }

  WebDavClient(this._config) {
    _client = webdav.newClient(_config.server, user: _config.username, password: _config.password, debug: false);
  }

  @override
  Future<ExceptionInfo?> testConnect() async {
    try {
      await _client.ping();
      return null;
    } catch (err, stack) {
      return ExceptionInfo(err: err, stackTrace: stack);
    }
  }

  String _removeSuffix(String str) {
    return str.replaceFirst(RegExp(r'/+$'), '');
  }

  @override
  Future<List<String>> listRootDirectoryNames() async {
    final list = await _client.readDir("");
    return list.where((item) => (item.isDir ?? false) && (item.name ?? "").isNotEmpty).map((item) => item.path!).toList()..sort();
  }

  @override
  Future<List<StorageItem>> list({String path = "", bool recursive = false}) async {
    final dirPath = (_baseDir + path).unixPath;
    if (!await isDirectory(path)) {
      throw '$path is not directory!';
    }
    List<StorageItem> result = [];
    final items = await _client.readDir(dirPath);
    for (var item in items) {
      late List<StorageItem> children;
      if (recursive && item.isDir!) {
        children = await list(path: item.path!, recursive: true);
      } else {
        children = [];
      }
      result.add(
        StorageItem(
          path: item.path!,
          name: item.name!,
          isDir: item.isDir!,
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
    var dirPath = _baseDir + path;
    try {
      final file = await _client.readProps(dirPath);
      return file.isDir == true;
    } catch (err, stack) {
      Log.error(tag, _config.toString() + err.toString(), stack);
      return false;
    }
  }

  @override
  Future<bool> createDirectory(String path) async {
    final dirPath = _baseDir + path;
    try {
      await _client.mkdirAll(dirPath);
      return true;
    } catch (err, stack) {
      Log.error(tag, _config.toString() + err.toString(), stack);
      return false;
    }
  }

  @override
  Future<bool> deleteDirectory(String path) async {
    try {
      final isDir = await isDirectory(path);
      if (!isDir) {
        return false;
      }
      await _client.remove(path);
      return true;
    } catch (err, stack) {
      Log.error(tag, _config.toString() + err.toString(), stack);
      return false;
    }
  }

  //endregion

  //region File

  @override
  Future<bool> isFile(String path) async {
    var filePath = _baseDir + path;
    try {
      final file = await _client.readProps(filePath, isFile: true);
      if (file.isDir == null) {
        return false;
      } else {
        return !file.isDir!;
      }
    } catch (err, stack) {
      Log.error(tag, _config.toString() + err.toString(), stack);
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
    var filePath = _baseDir + path;
    filePath = _removeSuffix(filePath.unixPath);
    try {
      if (createDir) {
        final dir = (path.split(Constants.unixDirSeparate)..removeLast()).join(Constants.unixDirSeparate);
        final result = await createDirectory(dir);
        if (!result) {
          return false;
        }
      }
      await _client.write(filePath, bytes, onProgress: onProgress);
      return true;
    } catch (err, stack) {
      Log.error(tag, _config.toString() + err.toString(), stack);
      return false;
    }
  }

  @override
  Future<bool> uploadFile(
    String path,
    String localFilePath, {
    StorageProgressFunc? onProgress,
  }) async {
    try {
      if (!await File(localFilePath).exists()) {
        return false;
      }
      var filePath = _baseDir + path;
      await _client.writeFromFile(localFilePath, filePath, onProgress: onProgress);
      return true;
    } catch (err, stack) {
      Log.error(tag, _config.toString() + err.toString(), stack);
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
    try {
      var filePath = _baseDir + path;
      if (!await isFile(path)) {
        return false;
      }
      var localDir = Directory(localPath);
      if (!isLocalDir) {
        localDir = File(localPath).parent;
      } else {
        var props = await _client.readProps(filePath);
        if (!localPath.endsWith("/")) {
          localPath += "/";
        }
        localPath += props.name!;
      }
      await localDir.create(recursive: true);
      await _client.read2File(filePath, localPath, onProgress: onProgress);
      return true;
    } catch (err, stack) {
      Log.error(tag, _config.toString() + err.toString(), stack);
      return false;
    }
  }

  @override
  Future<List<int>?> readFileBytes(
    String path, {
    StorageProgressFunc? onProgress,
  }) async {
    try {
      var filePath = _baseDir + path;
      if (!await isFile(path)) {
        return null;
      }
      return await _client.read(filePath, onProgress: onProgress);
    } catch (err, stack) {
      Log.error(tag, _config.toString() + err.toString(), stack);
      return null;
    }
  }

  @override
  Future<bool> deleteFile(String path) async {
    try {
      final isFile = await this.isFile(path);
      if (!isFile) {
        return false;
      }
      var filePath = _baseDir + path;
      await _client.remove(filePath);
      return true;
    } catch (err, stack) {
      Log.error(tag, _config.toString() + err.toString(), stack);
      return false;
    }
  }

  //endregion
}
