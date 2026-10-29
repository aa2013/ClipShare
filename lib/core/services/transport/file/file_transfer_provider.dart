import 'dart:async';

import 'package:clipshare/core/database/app_database.dart';
import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/database/dao/history_dao.dart';
import 'package:clipshare/core/runtime/snowflake/id_provider.dart';
import 'package:clipshare/core/services/device/device_provider.dart';
import 'package:clipshare/core/services/device/local_device_info.dart';
import 'package:clipshare/core/services/device/local_device_info_provider.dart';
import 'package:clipshare/core/services/history/history_event.dart';
import 'package:clipshare/core/services/history/history_recorder_provider.dart';
import 'package:clipshare/core/services/transport/file/enums/file_transfer_direction.dart';
import 'package:clipshare/core/services/transport/file/enums/file_transfer_state.dart';
import 'package:clipshare/core/services/transport/file/models/file_transfer_task.dart';
import 'package:clipshare/core/services/transport/file/models/pending_transfer_file.dart';
import 'package:clipshare/core/services/transport/file/models/protocol/file_name_codec.dart';
import 'package:clipshare/core/services/transport/file/receiver/file_receiver_provider.dart';
import 'package:clipshare/core/services/transport/file/sender/direct_socket_send_channel.dart';
import 'package:clipshare/core/services/transport/file/sender/file_send_channel.dart';
import 'package:clipshare/core/services/transport/file/sender/forward_send_channel.dart';
import 'package:clipshare/core/services/transport/storage/storage_provider.dart';
import 'package:clipshare/shared/enums/history_content_type.dart';
import 'package:clipshare/shared/extensions/string_extension.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:clipshare/shared/utils/parallerl_task.dart';
import 'package:clipshare/shared/utils/snowflake.dart';
import 'package:collection/collection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'file_transfer_provider.g.dart';

/// state 快照推送节流间隔
const _stateSyncInterval = Duration(milliseconds: 200);

/// 速度采样窗口，两次采样间隔达到该值才刷新速度
const _speedSampleInterval = Duration(milliseconds: 500);

/// 文件传输状态中枢：持有发送队列与全部收发任务，按设备串行调度发送。
/// state 为任务快照，UI 直接 watch 展示队列与进度。
@Riverpod(keepAlive: true)
class FileTransferNotifier extends _$FileTransferNotifier {
  static const tag = 'FileTransferNotifier';
  static const _uuid = Uuid();

  /// 全部任务的真身，字段随进度原地更新，state 为其节流快照
  final _tasks = <String, FileTransferTask>{};

  /// 进行中发送任务的取消令牌，taskId -> source
  final _cancelSources = <String, CancelTokenSource>{};

  /// 速度采样点，taskId -> (采样时间, 采样字节)
  final _speedSamples = <String, (DateTime, int)>{};

  /// 正在执行发送的设备集合，保证同一设备的发送严格串行
  final _pumpingDevices = <String>{};

  Timer? _syncTimer;
  var _syncScheduled = false;

  DeviceState get _deviceState => ref.read(deviceProvider).requireValue;

  LocalDeviceInfo get _localDeviceInfo => ref.read(localDeviceInfoProvider).requireValue;

  HistoryDao get _historyDao => ref.read(appDbProvider).requireValue.historyDao;

  HistoryRecorderNotifier get _historyRecorder => ref.read(historyRecorderProvider.notifier);

  FileReceiverNotifier get _receiver => ref.read(fileReceiverProvider.notifier);

  DirectSocketSendChannel get _directChannel => ref.read(directSocketSendChannelProvider.notifier);

  ForwardSendChannel get _forwardChannel => ref.read(forwardSendChannelProvider.notifier);

  StorageNotifier get _storage => ref.read(storageProvider.notifier);

  Snowflake get _idGenerator => ref.read(idProvider);

  @override
  List<FileTransferTask> build() {
    ref.onDispose(_dispose);
    return const [];
  }

  void _dispose() {
    _syncTimer?.cancel();
  }

  //region 发送调度

  /// 为设备入队待发送文件并启动调度；设备协议未知时忽略并告警
  Future<void> sendFiles(BaseDeviceInfo device, List<PendingTransferFile> files) async {
    if (files.isEmpty) {
      return;
    }
    final protocol = _deviceState.registry.getProtocol(device.guid);
    if (protocol == null) {
      logger.warn(tag, 'skip send because transport protocol is unknown. devId=${device.guid}');
      return;
    }
    for (var file in files) {
      final protocolFileName = buildProtocolFileName(file.relativeDirs, file.fileName);
      final task = FileTransferTask(
        id: _uuid.v4(),
        direction: .send,
        devId: device.guid,
        devName: device.name,
        fileName: protocolFileName,
        localPath: file.filePath,
        isUri: file.isUri,
        totalSize: file.size,
        fileId: _idGenerator.nextId(),
        groupKey: parseProtocolFileGroupKey(protocolFileName),
      );
      _tasks[task.id] = task;
    }
    _scheduleStateSync();
    _pump(device.guid);
  }

  /// 推进指定设备的发送队列；同一设备同时只执行一个任务
  void _pump(String devId) {
    if (_pumpingDevices.contains(devId)) {
      return;
    }
    final next = _tasks.values.firstWhereOrNull(
      (task) => task.direction == .send && task.devId == devId && task.state == .pending,
    );
    if (next == null) {
      return;
    }
    _pumpingDevices.add(devId);
    _runSendTask(next).whenComplete(() {
      _pumpingDevices.remove(devId);
      _pump(devId);
    });
  }

  /// 执行单个发送任务并按结果收口状态
  Future<void> _runSendTask(FileTransferTask task) async {
    final device = _findOnlineDevice(task.devId);
    if (device == null) {
      logger.warn(tag, 'send aborted because device is offline. devId=${task.devId}, file=${task.fileName}');
      _updateTask(task.id, state: .error);
      return;
    }
    final source = CancelTokenSource();
    _cancelSources[task.id] = source;
    final token = source.token;
    _updateTask(task.id, state: .transferring);
    final job = FileSendJob(
      device: device,
      task: task,
      cancelToken: token,
      onProgress: (bytes) => _updateProgress(task.id, bytes),
    );
    try {
      await _sendByProtocol(job);
      if (token.isCanceled) {
        _updateTask(task.id, state: .canceled);
      } else {
        _updateTask(task.id, state: .done);
        await _recordSendHistory(task);
      }
    } catch (err, stack) {
      if (err is FileTransferCanceledException || token.isCanceled) {
        _updateTask(task.id, state: .canceled);
      } else {
        logger.error(tag, 'send file failed. file=${task.fileName}, err=$err', stack);
        _updateTask(task.id, state: .error);
      }
    } finally {
      _cancelSources.remove(task.id);
      _speedSamples.remove(task.id);
    }
  }

  /// 按设备协议选择通道执行发送
  Future<void> _sendByProtocol(FileSendJob job) async {
    final protocol = _deviceState.registry.getProtocol(job.device.guid);
    switch (protocol) {
      case .direct:
        await _directChannel.send(job);
      case .server:
        await _forwardChannel.send(job);
      case .webdav:
      case .s3:
        await _storage.sendFile(job);
      case null:
        throw Exception('device protocol is unknown. devId=${job.device.guid}');
    }
  }

  /// 查找在线设备信息
  BaseDeviceInfo? _findOnlineDevice(String devId) {
    return _deviceState.onlineList.firstWhereOrNull((dev) => dev.guid == devId);
  }

  /// 发送完成后写入本机文件历史并广播列表刷新
  Future<void> _recordSendHistory(FileTransferTask task) async {
    final content = task.isUri ? task.localPath.safeDecodeUri() : task.localPath;
    final history = History(
      id: task.fileId,
      uid: 0,
      time: task.startTime.toString(),
      content: content,
      type: HistoryContentType.file.value,
      devId: _localDeviceInfo.baseDeviceInfo.guid,
      top: false,
      sync: true,
      size: task.totalSize,
    );
    await _historyDao.add(history);
    _historyRecorder.emitDelta(HistoryDeltaEvent(history: history, operation: .add, fromSync: true));
  }

  //endregion

  //region 终止与清理

  /// 终止单个任务：排队中直接置为已取消，传输中通过取消令牌或接收器中断
  void cancelTask(String taskId) {
    final task = _tasks[taskId];
    if (task == null || !task.cancellable) {
      return;
    }
    if (task.direction == .receive) {
      _receiver.abortTask(taskId);
      return;
    }
    if (task.state == .pending) {
      _updateTask(taskId, state: .canceled);
      return;
    }
    _cancelSources[taskId]?.cancel();
  }

  /// 终止指定分组内的全部可取消任务
  void cancelGroup(FileTransferDirection direction, String devId, String groupKey) {
    final ids = _tasks.values
        .where((task) => task.direction == direction && task.devId == devId && task.groupKey == groupKey && task.cancellable)
        .map((task) => task.id)
        .toList();
    for (var id in ids) {
      cancelTask(id);
    }
  }

  /// 清除已取消与失败的任务；指定方向时仅清除该方向
  void clearFailed([FileTransferDirection? direction]) {
    final removedIds = _tasks.values
        .where(
          (task) =>
              (task.state == .canceled || task.state == .error) &&
              (direction == null || task.direction == direction),
        )
        .map((task) => task.id)
        .toList();
    if (removedIds.isEmpty) {
      return;
    }
    for (var id in removedIds) {
      _tasks.remove(id);
      _speedSamples.remove(id);
    }
    _scheduleStateSync();
  }

  //endregion

  //region 接收任务登记（由 FileReceiverNotifier 调用）

  /// 登记接收任务并返回任务 id
  String registerReceiveTask({
    required String devId,
    required String devName,
    required String fileName,
    required String localPath,
    required int totalSize,
    required int fileId,
  }) {
    final task = FileTransferTask(
      id: _uuid.v4(),
      direction: .receive,
      devId: devId,
      devName: devName,
      fileName: fileName,
      localPath: localPath,
      totalSize: totalSize,
      fileId: fileId,
      groupKey: parseProtocolFileGroupKey(fileName),
      state: .transferring,
    );
    _tasks[task.id] = task;
    _scheduleStateSync();
    return task.id;
  }

  /// 更新接收进度
  void updateReceiveProgress(String taskId, int transferredBytes) {
    _updateProgress(taskId, transferredBytes);
  }

  /// 接收完成收口
  void completeReceiveTask(String taskId) {
    _updateTask(taskId, state: .done);
  }

  /// 接收失败收口
  void failReceiveTask(String taskId) {
    _updateTask(taskId, state: .error);
  }

  /// 接收取消收口
  void cancelReceiveTask(String taskId) {
    _updateTask(taskId, state: .canceled);
  }

  //endregion

  //region 状态推送

  /// 原地更新任务字段并推送节流快照；完成的任务立即移除
  void _updateTask(String taskId, {FileTransferState? state}) {
    final task = _tasks[taskId];
    if (task == null) {
      return;
    }
    if (state != null) {
      task.state = state;
    }
    if (task.state == .done) {
      _tasks.remove(taskId);
      _speedSamples.remove(taskId);
    }
    _scheduleStateSync();
  }

  /// 更新任务进度并按采样窗口估算速度
  void _updateProgress(String taskId, int transferredBytes) {
    final task = _tasks[taskId];
    if (task == null) {
      return;
    }
    task.transferredBytes = transferredBytes;
    final now = DateTime.now();
    final last = _speedSamples[taskId];
    if (last == null) {
      _speedSamples[taskId] = (now, transferredBytes);
    } else {
      final offsetMs = now.difference(last.$1).inMilliseconds;
      if (offsetMs >= _speedSampleInterval.inMilliseconds) {
        task.speed = (transferredBytes - last.$2) / (offsetMs / 1000);
        _speedSamples[taskId] = (now, transferredBytes);
      }
    }
    _scheduleStateSync();
  }

  /// 防抖推送任务快照，避免高频进度刷新导致 UI 过频重建
  void _scheduleStateSync() {
    if (_syncScheduled) {
      return;
    }
    _syncScheduled = true;
    _syncTimer = Timer(_stateSyncInterval, () {
      _syncScheduled = false;
      state = _tasks.values.toList();
    });
  }

  //endregion
}
