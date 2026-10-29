import 'dart:async';
import 'dart:io';

import 'package:clipshare/core/services/device/local_device_info.dart';
import 'package:clipshare/core/services/device/local_device_info_provider.dart';
import 'package:clipshare/core/services/transport/file/models/protocol/forward_send_file_msg.dart';
import 'package:clipshare/core/services/transport/file/sender/file_send_channel.dart';
import 'package:clipshare/core/services/transport/socket/forward/forward_server_provider.dart';
import 'package:clipshare/core/settings/forward/forward_settings.dart';
import 'package:clipshare/core/settings/forward/forward_settings_provider.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'forward_send_channel.g.dart';

/// 中转通道：向中转服务器发起文件连接，等待接收端就绪后传输文件流
@Riverpod(keepAlive: true)
class ForwardSendChannel extends _$ForwardSendChannel implements FileSendChannel {
  static const tag = 'ForwardSendChannel';

  /// 等待接收端连上中转服务器的超时时间
  static const _receiverReadyTimeout = Duration(seconds: 5);

  /// 等待接收端就绪的发送任务，fileId -> completer
  final _readyWaiters = <int, Completer<void>>{};

  ForwardServerNotifier get _forwardServer => ref.read(forwardServerProvider.notifier);

  ForwardSettings get _forwardSettings => ref.read(forwardSettingsProvider).requireValue;

  LocalDeviceInfo get _localDeviceInfo => ref.read(localDeviceInfoProvider).requireValue;

  @override
  void build() {}

  @override
  Future<void> send(FileSendJob job) async {
    final task = job.task;
    final serverConfig = _forwardSettings.serverConfig;
    if (!_forwardSettings.enable || serverConfig == null) {
      throw Exception('forward server is not available.');
    }
    final client = await Socket.connect(serverConfig.host, serverConfig.port);
    try {
      final msg = ForwardSendFileMsg(
        fileName: task.fileName,
        size: task.totalSize,
        fileId: task.fileId,
        targetDevId: task.devId,
        selfDevId: _localDeviceInfo.baseDeviceInfo.guid,
      );
      client.add(msg.encodePacket());
      await _waitReceiverReady(task.fileId);
      final source = await openSendSourceStream(task.localPath, isUri: task.isUri);
      final tracked = trackFileStream(source, cancelToken: job.cancelToken, onProgress: job.onProgress);
      await client.addStream(tracked);
    } catch (err, stack) {
      if (err is TimeoutException) {
        //接收端超时未连接，通知中转服务器取消本次文件中转
        _forwardServer.sendCancelFileRelay(task.devId);
      }
      logger.error(tag, 'send file failed. file=${task.fileName}, err=$err', stack);
      rethrow;
    } finally {
      _readyWaiters.remove(task.fileId);
      client.destroy();
    }
  }

  /// 中转服务器通知接收端已连接时按 fileId 唤醒等待中的发送任务
  void onReceiverConnected(int fileId) {
    _readyWaiters.remove(fileId)?.complete();
  }

  /// 等待接收端连上中转服务器，超时抛出 [TimeoutException]
  Future<void> _waitReceiverReady(int fileId) {
    final waiter = Completer<void>();
    _readyWaiters[fileId] = waiter;
    return waiter.future.timeout(_receiverReadyTimeout);
  }
}
