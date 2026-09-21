import 'dart:io';

import 'package:clipshare/core/constants/platform_constants.dart';
import 'package:clipshare/core/utils/permission/permission_handler_facade.dart';
import 'package:clipshare/shared/extensions/string_extension.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:open_file_plus/open_file_plus.dart';
import 'package:path/path.dart' as path;
import 'package:resolve_windows_shortcut/resolve_windows_shortcut.dart';

extension DirectoryExt on Directory {
  static const tag = 'DirectoryExt';

  String get name => path.basename(this.path);

  String get normalizePath {
    if (isWindows) {
      return absolute.path.replaceAll(RegExp(r'(/+|\\+)'), '\\');
    } else {
      return absolute.path.replaceAll(RegExp(r'(/+|\\+)'), '/');
    }
  }

  Future<bool> existsTargetFileShortcut(String realPath) async {
    if (!isWindows) return false;
    realPath = realPath.normalizePath;
    for (var entity in listSync(recursive: true)) {
      if (entity is Directory) return false;
      final file = entity as File;
      if (file.extension != 'lnk') return false;
      try {
        final String resolvedShortcutPath = await file.resolveIfShortcut();
        if (resolvedShortcutPath.normalizePath == realPath) {
          return true;
        }
      } catch (err, stack) {
        logger.error(tag, err, stack);
      }
    }
    return false;
  }

  Future<void> deleteTargetFileShortcut(String realPath) async {
    if (!isWindows) return;
    realPath = realPath.normalizePath;
    for (var entity in listSync(recursive: true)) {
      if (entity is Directory) return;
      final file = entity as File;
      if (file.extension != 'lnk') return;
      try {
        final String resolvedShortcutPath = await file.resolveIfShortcut();
        if (resolvedShortcutPath.normalizePath == realPath) {
          return file.deleteSync();
        }
      } catch (err, stack) {
        logger.error(tag, err, stack);
      }
    }
  }
}

extension FileExt on File {
  String get normalizePath {
    return absolute.path.normalizePath;
  }

  String get fileName {
    return absolute.path
        .replaceFirst(absolute.parent.path, '')
        //去除重复斜杠
        .replaceAll(RegExp(r'(/+|\\+)'), '');
  }

  String get fileNameWithoutExt {
    var name = fileName;
    var extName = extension ?? '';
    //去除扩展名
    if (extName.isNotEmpty) {
      name = name.replaceLast('.$extName', '');
    }
    return name;
  }

  String? get extension {
    final name = fileName;
    if (!name.contains('.')) return null;
    return name.split('.').last;
  }

  String buildDuplicateSeqName() {
    var name = fileNameWithoutExt;
    var extName = extension ?? '';
    const pattern = r'\(\d+\)$';
    final regExp = RegExp(pattern);
    final defaultSeqName = "$name(1)${extName.isEmpty ? "" : "."}$extName";
    if (name.matchRegExp(pattern)) {
      //如果已经包含序号判断是否为序号本身
      if (name.replaceAll(RegExp(pattern), '').isEmpty) {
        return defaultSeqName;
      }
      //提取序号并+1
      final start = regExp.firstMatch(name)!.start;
      var seq =
          name.substring(start).replaceAll(RegExp(r'[\\(\\)]'), '').toInt() + 1;
      name = name.replaceAll(regExp, '');
      return "$name($seq)${extName.isEmpty ? "" : "."}$extName";
    }
    return defaultSeqName;
  }

  Future<String?> get md5 async {
    if (!existsSync()) {
      return null;
    }
    return crypto.md5.convert(await readAsBytes()).toString();
  }

  bool get isMediaFile {
    // 获取文件扩展名（小写处理）
    var extName = extension?.toLowerCase();
    if (extName == null) {
      return false;
    }

    // 常见的图片、音频、视频文件扩展名
    const imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
    const audioExtensions = ['mp3', 'wav', 'aac', 'flac', 'ogg', 'm4a'];
    const videoExtensions = ['mp4', 'avi', 'mkv', 'mov', 'wmv', 'flv'];

    // 判断文件是否属于以上三类之一
    return imageExtensions.contains(extName) ||
        audioExtensions.contains(extName) ||
        videoExtensions.contains(extName);
  }

  Future<void> openPath() async {
    if (isWindows) {
      await Process.run('explorer /select,"${this.path.normalizePath}"', []);
    } else {
      if (isAndroid && this.path.toString().toLowerCase().endsWith('apk')) {
        final granted = await Permission.requestInstallPackages.isGranted;
        if (!granted) {
          final status = await Permission.requestInstallPackages.request();
          if (status.isGranted) {
            await OpenFile.open(this.path);
            return;
          }
        }
      }
      await OpenFile.open(parent.path);
    }
  }
}

