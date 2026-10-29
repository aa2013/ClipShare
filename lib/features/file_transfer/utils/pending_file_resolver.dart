import 'dart:io';

import 'package:clipshare/core/extensions/file_extension.dart';
import 'package:clipshare/core/services/transport/file/models/pending_transfer_file.dart';
import 'package:clipshare/shared/models/drop/my_drop_item.dart';
import 'package:clipshare/shared/utils/file_util.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:uri_file_reader/uri_file_reader.dart';

/// 拖入/选择文件的解析结果
class PendingResolveResult {
  /// 解析成功的待发送条目（文件夹保留为单条目）
  final List<PendingTransferFile> files;

  /// 无法解析的 content uri 数量
  final int failedCount;

  const PendingResolveResult({
    required this.files,
    required this.failedCount,
  });
}

/// 将拖入或选择的文件解析为待发送条目；文件夹保留为单条目，发送时再展开内部文件
Future<PendingResolveResult> resolvePendingFiles(List<DropItem> items) async {
  final files = <PendingTransferFile>[];
  var failedCount = 0;
  for (final item in items) {
    if (item is DropItemFileUri) {
      //Android content uri：解析文件名与大小后入队
      final fileInfo = await uriFileReader.getFileInfoFromUri(item.path);
      if (fileInfo == null) {
        failedCount++;
        continue;
      }
      files.add(PendingTransferFile(
        filePath: item.path,
        isUri: true,
        fileName: fileInfo.fileName,
        size: fileInfo.size,
      ));
      continue;
    }
    final path = item.path;
    if (FileSystemEntity.typeSync(path) == FileSystemEntityType.directory) {
      files.add(PendingTransferFile(
        filePath: path,
        isDirectory: true,
        fileName: item.name,
        size: 0,
      ));
      continue;
    }
    files.add(PendingTransferFile(
      filePath: path,
      fileName: item.name,
      size: File(path).lengthSync(),
    ));
  }
  return PendingResolveResult(files: files, failedCount: failedCount);
}

/// 展开待发列表中的文件夹条目为文件明细，相对目录以文件夹父目录为根
Future<List<PendingTransferFile>> expandPendingFiles(List<PendingTransferFile> files) async {
  final result = <PendingTransferFile>[];
  for (final file in files) {
    if (!file.isDirectory) {
      result.add(file);
      continue;
    }
    final rootDir = Directory(file.filePath).parent.path;
    final innerFiles = await FileUtil.listFiles(file.filePath);
    for (final innerFile in innerFiles) {
      final relativeDirs = innerFile.parent.path
          .replaceFirst(rootDir, '')
          .split(RegExp(r'(/+|\\+)'))
          .where((part) => part.isNotEmpty)
          .toList();
      result.add(PendingTransferFile(
        filePath: innerFile.path,
        fileName: innerFile.fileName,
        size: innerFile.lengthSync(),
        relativeDirs: relativeDirs,
      ));
    }
  }
  return result;
}
