class AppPaths {
  ///存储根路径
  ///后续接收的文件和截图都在此下创建文件
  final String rootStorePath;

  ///接收的文件存储目录
  ///桌面端基于 [rootStorePath]
  ///Android 端默认基于 Downloads/ClipShare
  final String fileStorePath;

  ///截图存储目录
  ///桌面端基于 [rootStorePath]
  ///移动端基于 [imageStorePath]
  final String screenShotStorePath;

  ///Android 端图片存储路径
  final String imageStorePath;

  const AppPaths({
    required this.rootStorePath,
    required this.fileStorePath,
    required this.screenShotStorePath,
    required this.imageStorePath,
  });
}
