import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:clipshare/core/constants/app_constants.dart';
import 'package:clipshare/core/constants/platform_constants.dart';
import 'package:clipshare/core/extensions/file_extension.dart';
import 'package:clipshare/core/providers/settings/app_paths/app_paths.dart';
import 'package:clipshare/core/utils/file_util.dart';
import 'package:clipshare/shared/extensions/string_extension.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'app_path_config.dart';

part 'app_paths_provider.g.dart';

const _defaultDatabaseFileName = 'clipshare.db';
const _tag = 'appPaths';

@Riverpod(keepAlive: true)
Future<AppPaths> appPaths(Ref ref) async {
  final customPathConfig = await _readPathConfig();
  final documentsPath = await _initDocumentsPath();
  final rootStorePath = await _initRootStorePath(
    customPathConfig,
    documentsPath,
  );
  final cachePath = await _initCachePath();
  final logsDir = await _initLogsDir(cachePath, documentsPath);
  logger.updateLogsDir(logsDir);
  final androidPrivatePicturesPath = await _initAndroidPrivatePicturesPath();
  return AppPaths(
    androidPrivateDocumentPath: await _initAndroidDocumentsPath(),
    androidPrivatePicturesPath: androidPrivatePicturesPath,
    documentsPath: documentsPath,
    rootStorePath: rootStorePath,
    imageStorePath: await _initImageStorePath(ref, androidPrivatePicturesPath),
    databasePath: await _initDatabasePath(customPathConfig, documentsPath),
    luaLibDirPath: await _initLuaLibDirPath(),
    cachePath: cachePath,
    logsDirPath: logsDir.normalizePath,
    windowsUserStartUpDirPath: _initWindowsStartupDirPath(),
    updateDownloadFileDirPath: _initUpdateDownloadPath(documentsPath),
  );
}

Future<String> _initAndroidDocumentsPath() async {
  if (Platform.isAndroid) {
    // /storage/emulated/0/Android/data/top.coclyun.clipshare/files/documents
    return (await getExternalStorageDirectories(
      type: StorageDirectory.documents,
    ))![0].path;
  } else {
    return '';
  }
}

Future<String> _initAndroidPrivatePicturesPath() async {
  if (Platform.isAndroid) {
    // /storage/emulated/0/Android/data/top.coclyun.clipshare/files/pictures
    return (await getExternalStorageDirectories(
      type: StorageDirectory.pictures,
    ))![0].path;
  } else {
    return '';
  }
}

Future<String> _initDocumentsPath() async {
  if (Platform.isAndroid) {
    return '$androidDocumentsPath/ClipShare/';
  } else {
    return '${(await getApplicationDocumentsDirectory()).path}/ClipShare/';
  }
}

///读取路径配置（环境变量 > 配置文件）
Future<CustomPathConfig> _readPathConfig() async {
  String? fileStorePath;
  String? databasePath;
  //读取本地文件的路径配置
  try {
    final file = File('custom_path.json');
    if (await file.exists()) {
      final content = await file.readAsString();
      final config = CustomPathConfig.fromJson(jsonDecode(content));
      fileStorePath = config.fileStorePath;
      databasePath = config.databasePath;
    }
  } catch (_) {
    //ignored
  }
  //读取环境变量中的路径配置
  var envFileStorePath = Platform.environment['CLIPSHARE_FILE_STORE_PATH'];
  var envDatabasePath = Platform.environment['CLIPSHARE_DATABASE_PATH'];
  //环境变量优先
  if (envFileStorePath != null) {
    fileStorePath = envFileStorePath;
  }
  if (envDatabasePath != null) {
    databasePath = envDatabasePath;
  }
  if (fileStorePath != null) {
    try {
      await Directory(fileStorePath).create(recursive: true);
    } catch (err, stack) {
      fileStorePath = null;
      logger.error(_tag, err, stack);
    }
  }
  if (databasePath != null) {
    try {
      await Directory(databasePath).create(recursive: true);
    } catch (err, stack) {
      databasePath = null;
      logger.error(_tag, err, stack);
    }
  }
  return CustomPathConfig(
    fileStorePath: fileStorePath,
    databasePath: databasePath,
  );
}

///文件默认存储路径
Future<String> _initRootStorePath(
  CustomPathConfig custom,
  String documentsPath,
) async {
  if (custom.fileStorePath != null) {
    return custom.fileStorePath!;
  }
  late String path;
  if (isAndroid) {
    path = '$androidDownloadPath/$appName';
  } else if (isMacOS && kReleaseMode) {
    var dir = await getApplicationDocumentsDirectory();
    path = '${dir.path}/$appName/files'.normalizePath;
  } else {
    path = '${Directory(Platform.resolvedExecutable).parent.path}/files';
    //如果当前路径可写则使用当前路径，如开发环境或者便携版本
    if (!FileUtil.testWriteable(path)) {
      final documentPath = documentsPath;
      path = '$documentPath/files'.normalizePath;
    }
  }
  var dir = Directory(path);
  try {
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
  } catch (err, stack) {
    logger.error(_tag, err, stack);
  }
  return Directory(path).normalizePath;
}

///数据库路径
Future<String> _initDatabasePath(
  CustomPathConfig custom,
  String documentsPath,
) async {
  // 数据库所在目录：优先用户自定义，其次桌面端取可写目录，其他平台默认空（工作目录下的相对路径）
  var databaseDir = '';
  if (custom.databasePath != null) {
    databaseDir = custom.databasePath!;
  } else if (isDesktop) {
    if (isMacOS) {
      databaseDir = documentsPath;
    } else {
      var dirPath = Directory(Platform.resolvedExecutable).parent.path;
      databaseDir = FileUtil.testWriteable(dirPath) ? dirPath : documentsPath;
    }
  }
  // 统一拼接数据库文件名
  return p.join(databaseDir, _defaultDatabaseFileName);
}

Future<String> _initLuaLibDirPath() async {
  final execDirPath = File(Platform.resolvedExecutable).parent.absolute.path;
  if (Platform.isMacOS) {
    return p.join(
      execDirPath,
      // .../Contents/MacOS
      '..',
      // 回到 Contents/
      'Frameworks',
      'App.framework',
      'Resources',
      // Contents/Frameworks/App.framework/Resources
      'flutter_assets',
      'assets',
      'lua',
    );
  } else if (Platform.isIOS) {
    return p.join(
      execDirPath,
      'Frameworks',
      'App.framework',
      'flutter_assets',
      'assets',
      'lua',
    );
  } else if (Platform.isAndroid) {
    final filesPath = await getExternalStorageDirectory();
    return p.join(filesPath!.path, 'lua');
  } else {
    return p.join(execDirPath, 'data', 'flutter_assets', 'assets', 'lua');
  }
}

String _initUpdateDownloadPath(String documentsPath) {
  if (Platform.isAndroid) {
    return androidDownloadPath;
  } else {
    return '$documentsPath/update';
  }
}

Future<String> _initCachePath() async {
  if (Platform.isAndroid) {
    // /storage/emulated/0/Android/data/top.coclyun.clipshare/cache
    return (await getExternalCacheDirectories())![0].path;
  } else {
    return (await getApplicationCacheDirectory()).path;
  }
}

String? _initWindowsStartupDirPath() {
  if (Platform.isWindows) {
    final username = Platform.environment['USERNAME'];
    if (username == null) {
      return null;
    } else {
      return r'C:\Users\' +
          username +
          r'\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup';
    }
  }
  return null;
}

///初始化日志路径
Future<Directory> _initLogsDir(String cachePath, String documentsPath) async {
  var path = '$cachePath/logs';
  if (Platform.isWindows) {
    //Windows 下如果没有权限写入默认位置则修改为document文件夹下
    path = Directory(
      '${Directory(Platform.resolvedExecutable).parent.path}/logs',
    ).absolute.normalizePath;
    if (!FileUtil.testWriteable(path)) {
      path = '$documentsPath/logs';
    }
  }
  var dir = Directory(path);
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }
  return Directory(path);
}

Future<String> _initImageStorePath(Ref ref,String androidPrivatePicturesPath) async {
  //todo 从数据库读取
  final storePath = '';
  if (!Platform.isAndroid) {
    return storePath;
  }
  if (storePath.isEmpty) {
    return androidPrivatePicturesPath;
  }
  return storePath;
}