import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:clipshare/core/constants/platform_constants.dart';
import 'package:clipshare/core/database/app_database.dart';
import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/database/dao/history_dao.dart';
import 'package:clipshare/core/database/tables/device.dart';
import 'package:clipshare/core/extensions/file_extension.dart';
import 'package:clipshare/core/platform/channels/android/android_channel_provider.dart';
import 'package:clipshare/core/services/device/device_provider.dart';
import 'package:clipshare/core/services/device/local_device_info.dart';
import 'package:clipshare/core/services/device/local_device_info_provider.dart';
import 'package:clipshare/core/services/history/history_event.dart';
import 'package:clipshare/core/services/history/history_recorder_provider.dart';
import 'package:clipshare/core/services/notify/notification_payload.dart';
import 'package:clipshare/core/services/notify/notify_provider.dart';
import 'package:clipshare/core/services/transport/client/storage/storage_client.dart';
import 'package:clipshare/core/services/transport/file/file_transfer_provider.dart';
import 'package:clipshare/core/services/transport/file/models/protocol/forward_receiver_ready_msg.dart';
import 'package:clipshare/core/services/transport/file/models/protocol/storage_file_info.dart';
import 'package:clipshare/core/services/transport/file/sender/file_send_channel.dart';
import 'package:clipshare/core/settings/app_paths/app_paths_provider.dart';
import 'package:clipshare/core/settings/notification/notification_settings.dart';
import 'package:clipshare/core/settings/notification/notification_settings_provider.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/enums/history_content_type.dart';
import 'package:clipshare/shared/extensions/string_extension.dart';
import 'package:clipshare/shared/utils/file_util.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'file_receiver_provider.g.dart';

/// 接收完成通知的 key 前缀，点击通知后打开对应文件
const _receivedFileNotifyKeyPrefix = 'receive-file';

/// 进行中的接收会话：持有文件流写句柄与取消标记，终止时由 [FileReceiverNotifier.abortTask] 中断清理
class _ReceiveSession {
  final Socket? socket;
  final IOSink? sink;
  final String localPath;

  /// 终止标记，文件流侧轮询到该标记后停止处理
  bool canceled = false;

  _ReceiveSession({
    this.socket,
    this.sink,
    required this.localPath,
  });
}

/// 文件接收器：统一处理直连、中转、存储中转三条通道的接收落盘、
/// 进度上报与完成收尾（历史记录、系统通知、媒体库扫描）。
@Riverpod(keepAlive: true)
class FileReceiverNotifier extends _$FileReceiverNotifier {
  static const tag = 'FileReceiverNotifier';

  /// 进行中的接收会话，taskId -> session
  final _activeReceives = <String, _ReceiveSession>{};

  FileTransferNotifier get _board => ref.read(fileTransferProvider.notifier);

  DeviceState get _deviceState => ref.read(deviceProvider).requireValue;

  LocalDeviceInfo get _localDeviceInfo => ref.read(localDeviceInfoProvider).requireValue;

  HistoryDao get _historyDao => ref.read(appDbProvider).requireValue.historyDao;

  HistoryRecorderNotifier get _historyRecorder => ref.read(historyRecorderProvider.notifier);

  NotifyNotifier get _notify => ref.read(notifyProvider.notifier);

  NotificationSettings get _notificationSettings => ref.read(notificationSettingsProvider).requireValue;

  AndroidChannelNotifier get _androidChannel => ref.read(androidChannelProvider.notifier);

  @override
  void build() {}

  //region 三条通道的接收入口

  /// 直连接收：反连发送端临时端口拉取文件流
  Future<void> receiveDirect({
    required String ip,
    required int port,
    required int size,
    required String fileName,
    required String devId,
    required int fileId,
  }) async {
    final socket = await Socket.connect(ip, port);
    await _receiveSocket(
      socket,
      fileName: fileName,
      totalSize: size,
      devId: devId,
      fileId: fileId,
    );
  }

  /// 中转接收：连上中转服务器并告知发送端就绪后拉取文件流
  Future<void> receiveForward({
    required String host,
    required int port,
    required int size,
    required String fileName,
    required String devId,
    required int fileId,
    required String targetDevId,
  }) async {
    final socket = await Socket.connect(host, port);
    final ready = ForwardReceiverReadyMsg(
      targetDevId: targetDevId,
      fileId: fileId,
      selfDevId: _localDeviceInfo.baseDeviceInfo.guid,
    );
    socket.add(ready.encodePacket());
    await _receiveSocket(
      socket,
      fileName: fileName,
      totalSize: size,
      devId: devId,
      fileId: fileId,
    );
  }

  /// 存储中转接收：从云端下载文件后走统一收尾，成功后清理云端文件
  Future<void> receiveFromStorage({
    required StorageClient client,
    required String datePath,
    required String fromDevId,
    required int fileId,
  }) async {
    final infoPath = '$datePath/files/$fileId';
    final infoBytes = await client.readFileBytes(infoPath);
    if (infoBytes == null) {
      logger.warn(tag, 'storage file info not found. path=$infoPath');
      return;
    }
    final info = StorageFileInfo.fromJson(jsonDecode(utf8.decode(infoBytes)));
    final storageFilePath = '$datePath/files/${info.fileName}';
    final localPath = await _resolveLocalPath(info.fileName);
    final taskId = _registerTask(
      fileName: info.fileName,
      localPath: localPath,
      totalSize: info.size,
      devId: fromDevId,
      fileId: fileId,
    );
    final session = _ReceiveSession(localPath: localPath);
    _activeReceives[taskId] = session;
    var completed = false;
    try {
      final downloaded = await client.downloadFile(
        storageFilePath,
        localPath,
        onProgress: (count, total) {
          if (session.canceled) {
            throw const FileTransferCanceledException();
          }
          _board.updateReceiveProgress(taskId, count);
        },
      );
      if (!downloaded) {
        throw Exception('download storage file failed: $storageFilePath');
      }
      completed = true;
      await _removeStorageFile(client, infoPath);
      await _removeStorageFile(client, storageFilePath);
      await _completeReceive(
        taskId: taskId,
        fileId: fileId,
        devId: fromDevId,
        localPath: localPath,
        totalSize: info.size,
      );
    } catch (err, stack) {
      if (!session.canceled) {
        _board.failReceiveTask(taskId);
        logger.error(tag, 'receive storage file failed. file=${info.fileName}, err=$err', stack);
      }
    } finally {
      _activeReceives.remove(taskId);
      if (!completed) {
        await _discardPartialFile(localPath);
      }
    }
  }

  //endregion

  /// 终止接收任务：中断文件流、删除半成品并标记取消
  Future<void> abortTask(String taskId) async {
    final session = _activeReceives.remove(taskId);
    if (session == null) {
      return;
    }
    session.canceled = true;
    session.socket?.destroy();
    await _discardPartialFile(session.localPath);
    _board.cancelReceiveTask(taskId);
  }

  //region socket 流接收

  /// 从 socket 接收文件流并落盘，仅在字节数匹配且写入完成后走成功收尾
  Future<void> _receiveSocket(
    Socket socket, {
    required String fileName,
    required int totalSize,
    required String devId,
    required int fileId,
  }) async {
    final startTime = DateTime.now();
    final localPath = await _resolveLocalPath(fileName);
    final taskId = _registerTask(
      fileName: fileName,
      localPath: localPath,
      totalSize: totalSize,
      devId: devId,
      fileId: fileId,
    );
    final sink = File(localPath).openWrite();
    final session = _ReceiveSession(socket: socket, sink: sink, localPath: localPath);
    _activeReceives[taskId] = session;
    var transferred = 0;
    var completed = false;
    try {
      // 经转换器统计字节进度后写入文件，addStream 自带背压避免数据积压内存
      final tracked = socket.cast<List<int>>().transform(
        StreamTransformer<List<int>, List<int>>.fromHandlers(
          handleData: (data, out) {
            if (session.canceled) {
              out.addError(const FileTransferCanceledException());
              out.close();
              return;
            }
            transferred += data.length;
            _board.updateReceiveProgress(taskId, transferred);
            out.add(data);
          },
        ),
      );
      await sink.addStream(tracked);
      if (session.canceled) {
        return;
      }
      // 流结束不代表文件已收完整
      if (transferred != totalSize) {
        throw FileSystemException('received file size mismatch: expected=$totalSize, actual=$transferred', localPath);
      }
      await sink.flush();
      if (session.canceled) {
        return;
      }
      completed = true;
      await _completeReceive(
        taskId: taskId,
        fileId: fileId,
        devId: devId,
        localPath: localPath,
        totalSize: totalSize,
        startTime: startTime,
      );
    } catch (err, stack) {
      if (!session.canceled) {
        _board.failReceiveTask(taskId);
        logger.error(tag, 'receive file failed. file=$fileName, err=$err', stack);
      }
    } finally {
      _activeReceives.remove(taskId);
      await sink.close();
      socket.destroy();
      if (!completed) {
        await _discardPartialFile(localPath);
      }
    }
  }

  //endregion

  //region 公共收尾

  /// 登记接收任务到状态中枢
  String _registerTask({
    required String fileName,
    required String localPath,
    required int totalSize,
    required String devId,
    required int fileId,
  }) {
    final devName = _deviceState.getStoredName(devId) ?? unknownDeviceName;
    return _board.registerReceiveTask(
      devId: devId,
      devName: devName,
      fileName: fileName,
      localPath: localPath,
      totalSize: totalSize,
      fileId: fileId,
    );
  }

  /// 清洗协议文件名（保留目录结构）、逐级创建目录并对重名文件追加序号
  Future<String> _resolveLocalPath(String fileName) async {
    final appPaths = await ref.read(appPathsProvider.future);
    final safeName = FileUtil.sanitizeReceivedFileName(fileName);
    var file = File('${appPaths.fileStorePath}/$safeName'.normalizePath);
    await file.parent.create(recursive: true);
    while (await file.exists()) {
      file = File('${file.parent.path}/${file.buildDuplicateSeqName()}'.normalizePath);
    }
    return file.path;
  }

  /// 接收完成收尾：标记完成、写历史记录并广播刷新、按配置发通知、Android 刷新媒体库
  Future<void> _completeReceive({
    required String taskId,
    required int fileId,
    required String devId,
    required String localPath,
    required int totalSize,
    DateTime? startTime,
  }) async {
    _board.completeReceiveTask(taskId);
    final history = History(
      id: fileId,
      uid: 0,
      time: (startTime ?? DateTime.now()).toString(),
      content: localPath,
      type: HistoryContentType.file.value,
      devId: devId,
      top: false,
      sync: true,
      size: totalSize,
    );
    try {
      await _historyDao.add(history);
      _historyRecorder.emitDelta(HistoryDeltaEvent(history: history, operation: .add, fromSync: true));
    } catch (err, stack) {
      logger.error(tag, 'record received file history failed. file=$localPath, err=$err', stack);
    }
    if (_notificationSettings.notifyOnReceivedFile) {
      await _notify.notify(
        title: localPath.split(RegExp(r'[/\\]')).last,
        content: TranslationKey.receivedFileNotifyContent.tr,
        key: '$_receivedFileNotifyKeyPrefix-$fileId',
        payload: NotificationPayload(
          type: .openFile,
          data: {
            NotificationPayload.filePathKey: localPath,
          },
        ),
      );
    }
    if (isAndroid && File(localPath).isMediaFile) {
      _androidChannel.notifyMediaScan(localPath);
    }
  }

  /// 删除接收失败的半成品文件
  Future<void> _discardPartialFile(String localPath) async {
    try {
      final file = File(localPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (err) {
      logger.warn(tag, 'delete partial file failed: $localPath, $err');
    }
  }

  /// 删除云端文件，失败仅告警不中断收尾
  Future<void> _removeStorageFile(StorageClient client, String path) async {
    if (!await client.deleteFile(path)) {
      logger.warn(tag, 'delete storage file failed. path=$path');
    }
  }

  //endregion
}
