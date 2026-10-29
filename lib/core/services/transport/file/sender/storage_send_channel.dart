import 'dart:convert';
import 'dart:io';

import 'package:clipshare/core/services/transport/client/storage/storage_client.dart';
import 'package:clipshare/core/services/transport/file/models/protocol/storage_file_info.dart';
import 'package:clipshare/core/services/transport/file/sender/file_send_channel.dart';
import 'package:clipshare/core/services/transport/storage/storage_ws_service.dart';
import 'package:clipshare/shared/extensions/time_extension.dart';
import 'package:clipshare/shared/models/websocket/ws_msg_data.dart';
import 'package:clipshare/shared/models/websocket/ws_msg_type.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:uri_file_reader/uri_file_reader.dart';

/// 存储中转文件上传执行器：上传文件本体与信息文件后经通知服务告知对端下载。
/// 依赖由 StorageNotifier 按当前连接注入。
class StorageSendChannel {
  static const tag = 'StorageSendChannel';

  final StorageClient client;
  final StorageWsService wsService;

  /// 本机设备 id（云端目录以发送端 id 归档）
  final String selfDevId;

  /// content uri 源文件的临时落盘目录
  final String cachePath;

  /// 云端历史日期目录构造（devId, yyyy-MM-dd -> path）
  final String Function(String devId, String date) buildDatePath;

  StorageSendChannel({
    required this.client,
    required this.wsService,
    required this.selfDevId,
    required this.cachePath,
    required this.buildDatePath,
  });

  /// 上传单文件；失败或取消时抛出异常，任务状态由调度方统一收口
  Future<void> send(FileSendJob job) async {
    final cancelToken = job.cancelToken;
    if (cancelToken.isCanceled) {
      throw const FileTransferCanceledException();
    }
    final task = job.task;
    final today = DateTime.now().format('yyyy-MM-dd');
    final filesDir = '${buildDatePath(selfDevId, today)}/files';
    final storageFilePath = '$filesDir/${task.fileName}';
    final infoFilePath = '$filesDir/${task.fileId}';

    // content uri 源先复制到缓存目录再上传，避免整读进内存
    var sourcePath = task.localPath;
    String? cachedUriFile;
    if (task.isUri) {
      cachedUriFile = await uriFileReader.copyFileFromUri(task.localPath, cachePath);
      if (cachedUriFile == null) {
        throw Exception('copy uri file failed: ${task.localPath}');
      }
      sourcePath = cachedUriFile;
    }
    try {
      if (!await client.createDirectory(filesDir)) {
        throw Exception('create storage dir failed: $filesDir');
      }
      final uploaded = await client.uploadFile(
        storageFilePath,
        sourcePath,
        onProgress: (count, total) {
          if (cancelToken.isCanceled) {
            throw const FileTransferCanceledException();
          }
          job.onProgress(count);
        },
      );
      if (cancelToken.isCanceled) {
        throw const FileTransferCanceledException();
      }
      if (!uploaded) {
        throw Exception('upload file failed: $storageFilePath');
      }
      final info = StorageFileInfo(fileName: task.fileName, size: task.totalSize);
      final infoCreated = await client.createFile(infoFilePath, utf8.encode(jsonEncode(info)), createDir: true);
      if (!infoCreated) {
        await client.deleteFile(storageFilePath);
        throw Exception('upload file info failed: $infoFilePath');
      }
      wsService.send(WsMsgData(WsMsgType.syncFile, '$today:$selfDevId:${task.fileId}', job.device.guid));
    } finally {
      await _deleteTempUriFile(cachedUriFile);
    }
  }

  /// 清理 content uri 源的临时缓存文件
  Future<void> _deleteTempUriFile(String? path) async {
    if (path == null) {
      return;
    }
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (err) {
      logger.warn(tag, 'delete cached uri file failed: $path, $err');
    }
  }
}
