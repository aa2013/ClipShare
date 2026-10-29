import 'package:clipshare/shared/extensions/string_extension.dart';

class AppPaths {
  ///Android 端私有文档存储路径
  final String androidPrivateDocumentPath;

  ///Android 端私有照片存储路径
  final String androidPrivatePicturesPath;

  ///系统默认文档路径
  final String documentsPath;

  ///存储根路径
  ///后续接收的文件和截图都在此下创建文件
  final String rootStorePath;

  ///接收的文件存储目录
  ///桌面端基于 [rootStorePath]
  ///Android 端默认基于 Downloads/ClipShare
  String get fileStorePath => '$rootStorePath/files'.normalizePath;

  ///截图存储目录
  ///桌面端基于 [rootStorePath]
  ///移动端基于 [imageStorePath]
  String get screenShotStorePath => '$rootStorePath/Screenshots'.normalizePath;

  ///Android 端图片存储路径
  final String imageStorePath;

  ///数据库路径
  final String databasePath;

  ///Lua库路径
  final String luaLibDirPath;

  ///缓存路径
  final String cachePath;

  ///日志文件夹路径
  final String logsDirPath;

  ///Windows开启启动文件夹路径
  final String? windowsUserStartUpDirPath;

  ///更新文件保存路径
  final String updateDownloadFileDirPath;

  const AppPaths({
    required this.rootStorePath,
    required this.imageStorePath,
    required this.databasePath,
    required this.androidPrivateDocumentPath,
    required this.androidPrivatePicturesPath,
    required this.documentsPath,
    required this.luaLibDirPath,
    required this.cachePath,
    required this.logsDirPath,
    this.windowsUserStartUpDirPath,
    required this.updateDownloadFileDirPath,
  });
}
