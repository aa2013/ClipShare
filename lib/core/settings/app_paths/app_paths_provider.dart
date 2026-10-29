import 'dart:io';

import 'package:clipshare/core/constants/app_constants.dart';
import 'package:clipshare/core/constants/platform_constants.dart';
import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/extensions/file_extension.dart';
import 'package:clipshare/core/settings/app_paths/app_path_config.dart';
import 'package:clipshare/core/settings/app_paths/app_paths.dart';
import 'package:clipshare/core/settings/app_paths/custom_path_resolver.dart';
import 'package:clipshare/shared/enums/config_key.dart';
import 'package:clipshare/shared/extensions/string_extension.dart';
import 'package:clipshare/shared/utils/file_util.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_paths_provider.g.dart';

const _tag = 'appPaths';

///应用路径集合
///
///存储类路径（文件存储根路径/图片存储路径）在平台默认值的基础上叠加数据库配置，
///依赖 appDb 读取配置表；数据库打开路径不依赖本 provider，不会形成循环依赖。
///[customPathConfig] 已由 main 在 runApp 前初始化。
@Riverpod(keepAlive: true)
Future<AppPaths> appPaths(Ref ref) async {
  final db = await ref.watch(appDbProvider.future);
  final configDao = db.configDao;
  final documentsPath = await initDocumentsPath();
  final androidPrivatePicturesPath = await _initAndroidPrivatePicturesPath();
  final cachePath = await _initCachePath();
  final logsDir = await _initLogsDir(cachePath, documentsPath);
  logger.updateLogsDir(logsDir);
  //文件存储根路径：custom_path.json/环境变量已配置时优先，其次数据库配置，均未配置时使用平台默认
  var rootStorePath = await _initRootStorePath(customPathConfig, documentsPath);
  if (customPathConfig.fileStorePath == null) {
    final dbFileStorePath = await configDao.getConfigByKey(
      ConfigKey.fileStorePath,
      '',
    );
    if (dbFileStorePath.isNotEmpty) {
      rootStorePath = _normalizeDirPath(dbFileStorePath);
    }
  }
  //图片存储路径：数据库配置，Android 下未配置时回退应用私有 Pictures 目录
  final dbImageStorePath = await configDao.getConfigByKey(
    ConfigKey.imageStorePath,
    '',
  );
  final imageStorePath = dbImageStorePath.isEmpty && isAndroid
      ? androidPrivatePicturesPath
      : dbImageStorePath;
  return AppPaths(
    androidPrivateDocumentPath: await _initAndroidDocumentsPath(),
    androidPrivatePicturesPath: androidPrivatePicturesPath,
    documentsPath: documentsPath,
    rootStorePath: rootStorePath,
    imageStorePath: imageStorePath,
    databasePath: await resolveDatabasePath(customPathConfig, documentsPath),
    luaLibDirPath: await _initLuaLibDirPath(),
    cachePath: cachePath,
    logsDirPath: logsDir.normalizePath,
    windowsUserStartUpDirPath: _initWindowsStartupDirPath(),
    updateDownloadFileDirPath: _initUpdateDownloadPath(documentsPath),
  );
}

///将数据库中配置的存储目录解析为绝对路径并统一路径分隔符
String _normalizeDirPath(String value) {
  return Directory(value).absolute.path.normalizePath;
}

Future<String> _initAndroidDocumentsPath() async {
  if (isAndroid) {
    // /storage/emulated/0/Android/data/top.coclyun.clipshare/files/documents
    return (await getExternalStorageDirectories(
      type: StorageDirectory.documents,
    ))![0].path;
  } else {
    return '';
  }
}

Future<String> _initAndroidPrivatePicturesPath() async {
  if (isAndroid) {
    // /storage/emulated/0/Android/data/top.coclyun.clipshare/files/pictures
    return (await getExternalStorageDirectories(
      type: StorageDirectory.pictures,
    ))![0].path;
  } else {
    return '';
  }
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

Future<String> _initLuaLibDirPath() async {
  final execDirPath = File(Platform.resolvedExecutable).parent.absolute.path;
  if (isMacOS) {
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
  } else if (isIOS) {
    return p.join(
      execDirPath,
      'Frameworks',
      'App.framework',
      'flutter_assets',
      'assets',
      'lua',
    );
  } else if (isAndroid) {
    final filesPath = await getExternalStorageDirectory();
    return p.join(filesPath!.path, 'lua');
  } else {
    return p.join(execDirPath, 'data', 'flutter_assets', 'assets', 'lua');
  }
}

String _initUpdateDownloadPath(String documentsPath) {
  if (isAndroid) {
    return androidDownloadPath;
  } else {
    return '$documentsPath/update';
  }
}

Future<String> _initCachePath() async {
  if (isAndroid) {
    // /storage/emulated/0/Android/data/top.coclyun.clipshare/cache
    return (await getExternalCacheDirectories())![0].path;
  } else {
    return (await getApplicationCacheDirectory()).path;
  }
}

String? _initWindowsStartupDirPath() {
  if (isWindows) {
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
  if (isWindows) {
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
