import 'dart:async';
import 'dart:io';

import 'package:clipshare/core/services/transport/file/models/protocol/direct_file_msg.dart';
import 'package:clipshare/core/services/transport/file/sender/file_send_channel.dart';
import 'package:clipshare/core/services/transport/socket/session/session_provider.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'direct_socket_send_channel.g.dart';

/// 直连通道：发送端开启临时数据端口并经会话发送控制消息，对端反连后传输文件流
@Riverpod(keepAlive: true)
class DirectSocketSendChannel extends _$DirectSocketSendChannel implements FileSendChannel {
  static const tag = 'DirectSocketSendChannel';

  /// 等待对端反连的超时时间
  static const _clientConnectTimeout = Duration(seconds: 5);

  SessionNotifier get _session => ref.read(sessionProvider.notifier);

  @override
  void build() {}

  @override
  Future<void> send(FileSendJob job) async {
    final task = job.task;
    ServerSocket? server;
    Socket? client;
    try {
      server = await ServerSocket.bind(InternetAddress.anyIPv4, 0);
      final clientReady = Completer<Socket>();
      server.listen((socket) {
        if (!clientReady.isCompleted) {
          clientReady.complete(socket);
        }
      });
      final msg = DirectFileMsg(
        fileName: task.fileName,
        size: task.totalSize,
        port: server.port,
        fileId: task.fileId,
      );
      await _session.sendData(job.device, .file, msg.toJson());
      client = await clientReady.future.timeout(_clientConnectTimeout);
      final source = await openSendSourceStream(task.localPath, isUri: task.isUri);
      final tracked = trackFileStream(source, cancelToken: job.cancelToken, onProgress: job.onProgress);
      await client.addStream(tracked);
    } catch (err, stack) {
      logger.error(tag, 'send file failed. file=${task.fileName}, err=$err', stack);
      rethrow;
    } finally {
      client?.destroy();
      await server?.close();
    }
  }
}
