import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:clipshare/shared/extensions/string_extension.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

///目录选择与可写性校验结果。
class WritableDirectoryPickResult {
  final String? path;
  final bool isUnwritable;

  const WritableDirectoryPickResult._({this.path, required this.isUnwritable});

  ///用户取消目录选择。
  const WritableDirectoryPickResult.cancelled() : this._(isUnwritable: false);

  ///用户选择的目录不可写。
  const WritableDirectoryPickResult.unwritable() : this._(isUnwritable: true);

  ///用户选择的可写目录。
  const WritableDirectoryPickResult.writable(String path) : this._(path: path, isUnwritable: false);
}

class FileUtil {
  FileUtil._private();

  static const _safeFileNameReplacement = '_';
  static const _windowsReservedFileNames = {
    'CON',
    'PRN',
    'AUX',
    'NUL',
    'COM1',
    'COM2',
    'COM3',
    'COM4',
    'COM5',
    'COM6',
    'COM7',
    'COM8',
    'COM9',
    'LPT1',
    'LPT2',
    'LPT3',
    'LPT4',
    'LPT5',
    'LPT6',
    'LPT7',
    'LPT8',
    'LPT9',
  };

  /// 清理接收端文件相对路径，避免远端文件名包含当前平台无法落盘的字符。
  ///
  /// [fileName] 可能携带同步文件夹层级，因此会逐段清理路径片段并保留目录结构。
  static String sanitizeReceivedFileName(String fileName) {
    final parts = fileName
        .split(RegExp(r'[/\\]'))
        .map(_sanitizeReceivedFileNamePart)
        .toList();
    return parts.join(path.separator);
  }

  /// 按平台规则清理单个路径片段，防止非法字符、保留名或路径穿越片段进入本地路径。
  static String _sanitizeReceivedFileNamePart(String part) {
    var safePart = part;
    if (Platform.isWindows) {
      safePart = safePart.replaceAll(RegExp(r'[<>:"|?*\x00-\x1F]'), _safeFileNameReplacement);
      safePart = safePart.replaceAll(RegExp(r'[. ]+$'), '');
    } else if (Platform.isMacOS) {
      safePart = safePart.replaceAll(RegExp(r'[:\x00]'), _safeFileNameReplacement);
    } else {
      safePart = safePart.replaceAll('\x00', _safeFileNameReplacement);
    }

    if (safePart.isEmpty || safePart == '.' || safePart == '..') {
      return _safeFileNameReplacement;
    }
    if (Platform.isWindows) {
      final baseName = safePart.split('.').first.toUpperCase();
      if (_windowsReservedFileNames.contains(baseName)) {
        return '$safePart$_safeFileNameReplacement';
      }
    }
    return safePart;
  }

  ///测试路径是否可写入
  static bool testWriteable(String dirPath) {
    final uuid = const Uuid().v4();
    final filePath = ('$dirPath/').normalizePath + uuid.toString();
    try {
      Directory(dirPath).createSync(recursive: true);
      final file = File(filePath);
      file.createSync();
      file.deleteSync();
      return true;
    } catch (e) {
      return false;
    }
  }

  ///选择目录并校验其是否可写，以便调用方区分取消选择和不可写目录。
  static Future<WritableDirectoryPickResult> pickWritableDirectory() async {
    final directory = await FilePicker.platform.getDirectoryPath(lockParentWindow: true);
    if (directory == null) {
      return const WritableDirectoryPickResult.cancelled();
    }
    if (!testWriteable(directory)) {
      return const WritableDirectoryPickResult.unwritable();
    }
    return WritableDirectoryPickResult.writable(Directory(directory).absolute.path.normalizePath);
  }

  ///递归获取文件夹大小
  static int getDirectorySize(String directoryPath) {
    Directory directory = Directory(directoryPath);
    int totalSize = 0;
    if (!directory.existsSync()) return 0;
    directory.listSync(recursive: true).forEach((FileSystemEntity entity) {
      if (entity is File) {
        totalSize += entity.lengthSync();
      }
    });
    return totalSize;
  }

  /// 递归删除目录下所有文件
  static void deleteDirectoryFiles(String directoryPath) {
    Directory directory = Directory(directoryPath);
    directory.listSync().forEach((FileSystemEntity entity) {
      if (entity is File) {
        entity.deleteSync(); // 删除文件
      } else if (entity is Directory) {
        deleteDirectoryFiles(entity.path); // 递归删除子目录下的文件
        entity.deleteSync(); // 删除子目录
      }
    });
  }

  /// 移动文件
  static void moveFile(String sourcePath, String destinationPath) {
    File sourceFile = File(sourcePath);
    File destFile = File(destinationPath);
    if (!destFile.parent.existsSync()) {
      destFile.parent.createSync(recursive: true);
    }
    destFile.writeAsBytesSync(sourceFile.readAsBytesSync());
    sourceFile.deleteSync();
  }

  ///导出文件
  static Future<String?> exportFile(
    String title,
    String fileName,
    String content,
  ) async {
    String? outputPath = await FilePicker.platform.saveFile(
      dialogTitle: title,
      fileName: fileName,
      bytes: utf8.encode(content),
    );
    return outputPath;
  }

  ///导出文件
  static Future<String?> exportFileBytes(
    String title,
    String fileName,
    Uint8List bytes,
  ) async {
    String? outputPath = await FilePicker.platform.saveFile(
      dialogTitle: title,
      fileName: fileName,
      bytes: bytes,
    );
    return outputPath;
  }

  ///获取文件夹下的所有文件
  static Future<List<File>> listFiles(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) {
      return [];
    }
    return await dir.list(recursive: true).where((item) => item is File).map((item) => item as File).toList();
  }

  ///选择文件
  static Future<List<PlatformFile>> pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result == null) return [];
    return result.files;
  }

  static Future<void> extractZipFile(File zipFile, Directory destDir) async {
    try {
      final fileData = await zipFile.readAsBytes();
      final bytes = Uint8List.fromList(fileData);
      final archive = ZipDecoder().decodeBytes(bytes);
      for (final file in archive.files) {
        if (file.isFile) {
          final filePath = path.join(destDir.path, file.name);

          final fileDir = path.dirname(filePath);
          await Directory(fileDir).create(recursive: true);

          final data = file.content as List<int>;
          await File(filePath).writeAsBytes(data);
        } else {
          // 如果是目录，则创建目录
          final dirPath = path.join(destDir.path, file.name);
          await Directory(dirPath).create(recursive: true);
        }
      }

      print('ZIP文件解压完成，路径: $destDir');
    } catch (e) {
      print('解压ZIP文件时出错: $e');
      rethrow;
    }
  }


  /// 复制 assets 文件到临时目录
  static Future<String> copyAssetToTemp(String assetPath) async {
    // 1. 读取 assets 文件内容
    final byteData = await rootBundle.load(assetPath);

    // 2. 获取临时目录
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/${assetPath.split('/').last}');

    // 3. 将 assets 写入临时文件
    await tempFile.writeAsBytes(
      byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
    );

    return tempFile.absolute.path;
  }
}
