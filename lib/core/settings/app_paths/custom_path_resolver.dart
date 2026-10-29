import 'dart:convert';
import 'dart:io';

import 'package:clipshare/core/constants/app_constants.dart';
import 'package:clipshare/core/constants/platform_constants.dart';
import 'package:clipshare/shared/utils/file_util.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import 'app_path_config.dart';

const _tag = 'customPathResolver';
const _defaultDatabaseFileName = 'clipshare.db';

///custom_path.json与环境变量解析出的自定义路径配置
///
///由 main 在 runApp 前完成初始化，之后全局只读。
late final CustomPathConfig customPathConfig;

///缓存初始化过程，防止重复调用导致 [customPathConfig] 二次赋值。
Future<void>? _initCustomPathConfigFuture;

///解析 custom_path.json/环境变量的自定义路径配置并赋值给 [customPathConfig]。
Future<void> initCustomPathConfig() {
  return _initCustomPathConfigFuture ??= _loadCustomPathConfig();
}

///读取 custom_path.json 与环境变量，创建目标目录并生成最终配置。
Future<void> _loadCustomPathConfig() async {
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
  customPathConfig = CustomPathConfig(
    fileStorePath: fileStorePath,
    databasePath: databasePath,
  );
}

///应用文档目录
Future<String> initDocumentsPath() async {
  if (isAndroid) {
    return '$androidDocumentsPath/ClipShare/';
  } else {
    return '${(await getApplicationDocumentsDirectory()).path}/ClipShare/';
  }
}

///数据库路径
///
///仅由 custom_path.json/环境变量与平台目录解析而来，数据库层在打开数据库前
///直接调用本方法，不依赖任何路径 provider，避免与 appPaths 相互依赖。
Future<String> resolveDatabasePath(
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
  if (databaseDir.isEmpty) {
    databaseDir = await sqflite.getDatabasesPath();
  }
  // 统一拼接数据库文件名
  return p.join(databaseDir, _defaultDatabaseFileName);
}
