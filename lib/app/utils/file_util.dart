import 'dart:convert';
import 'dart:io';

import 'package:clipshare/app/utils/extensions/string_extension.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';

class FileUtil {
  FileUtil._private();

  ///测试路径是否可写入
  static bool testWriteable(String dirPath) {
    final uuid = const Uuid().v4();
    final filePath = ("$dirPath/").normalizePath + uuid.toString();
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
      destFile.parent.createSync();
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
}
