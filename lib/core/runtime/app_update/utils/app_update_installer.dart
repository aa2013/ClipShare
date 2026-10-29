import 'dart:ffi';
import 'dart:io';

import 'package:clipshare/core/constants/platform_constants.dart';
import 'package:clipshare/core/extensions/file_extension.dart';
import 'package:clipshare/shared/extensions/string_extension.dart';
import 'package:clipshare/shared/models/update_log.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:flutter/foundation.dart';
import 'package:open_file_plus/open_file_plus.dart';
import 'package:path/path.dart' as p;
import 'package:zip_flutter/zip_flutter.dart';

/// 安装包路径与安装操作
class AppUpdateInstaller {
  static const _tag = 'AppUpdateInstaller';
  static const zipExtension = '.zip';
  static const installerTypes = <TargetPlatform, List<String>>{
    .windows: ['.exe', zipExtension],
    .linux: ['.deb', '.rpm', '.AppImage'],
  };

  /// 仅替换 URL 路径中的扩展名，保留查询参数和片段。
  static String replaceUrlExtension(String url, String extension) {
    assert(extension.startsWith('.'));
    final uri = Uri.parse(url);
    final path = uri.path;
    final dot = path.lastIndexOf('.');
    final slash = path.lastIndexOf('/');
    final base = dot > slash ? path.substring(0, dot) : path;
    return uri.replace(path: '$base$extension').toString();
  }

  /// 根据平台与 CPU 架构构造下载地址及本地路径。
  static ({String url, String fileName, String path}) resolve(
    UpdateLog log,
    String directory, {
    String? installerType,
  }) {
    var url = log.downloadUrl;
    if (installerType != null) {
      url = replaceUrlExtension(url, installerType);
    }
    if (isAndroid) {
      final arch = Abi.current().toString().split('_').last;
      if (arch == 'arm') {
        url = url.replaceFirst('arm64-v8a', 'armeabi-v7a');
      } else if (arch == 'x64') {
        url = url.replaceFirst('arm64-v8a', 'x86_64');
      }
    }
    var fileName = Uri.parse(url).path.replaceAll('\\', '/').split('/').last;
    if (isAndroid) {
      final version = log.version;
      fileName = 'ClipShare-${version.name}_${version.code}_$fileName';
    }
    return (url: url, fileName: fileName, path: p.join(directory, fileName));
  }

  /// 打开下载目录或执行安装；返回目录是否成功打开。
  static Future<bool> install(String path, {required bool openFolder, String? installerType}) async {
    final file = File(path);
    if (openFolder) {
      return file.openPath();
    }
    if (installerType == zipExtension && isWindows) {
      await _updateWindowsFromZip(file);
    } else {
      await OpenFile.open(path);
    }
    return true;
  }

  /// 解压 Windows 更新包，启动独立批处理后退出应用。
  static Future<void> _updateWindowsFromZip(File updateFile) async {
    final extractPath = p.join(updateFile.parent.absolute.path, 'temp').normalizePath;
    await Directory(extractPath).create(recursive: true);
    await ZipFile.openAndExtractAsync(updateFile.absolute.path, extractPath);
    final execDirPath = File(Platform.resolvedExecutable).parent.absolute.path;
    final batPath = p.join(execDirPath, 'data', 'flutter_assets', 'assets', 'scripts', 'update_windows.bat').normalizePath;
    final process = await Process.start(
      'cmd',
      ['/c', batPath, pid.toString(), extractPath],
      runInShell: true,
      mode: ProcessStartMode.detached,
      workingDirectory: execDirPath,
    );
    logger.debug(_tag, 'Update process started (PID: ${process.pid})');
    await Future<void>.delayed(const Duration(seconds: 1));
    exit(0);
  }
}
