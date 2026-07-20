import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:clipshare/app/handlers/socket/data_packet_splitter.dart';
import 'package:clipshare/app/handlers/socket/secure_socket_client.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/extensions/string_extension.dart';
import 'package:clipshare/app/utils/parallerl_task.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:synchronized/synchronized.dart';

class ForwardSocketClient {
  static const String tag = "ForwardSocketClient";

  static Map<String, dynamic> get baseMsg {
    final appConfig = Get.find<ConfigService>();
    return {
      "self": appConfig.device.guid,
      "devName": appConfig.localName,
      "platform": defaultTargetPlatform.name.upperFirst,
      "appVersion": appConfig.version.toString(),
    };
  }

  final String ip;
  late final int _port;
  late final Socket _socket;
  late final void Function(ForwardSocketClient client, String data)? _onMessage;
  void Function(Exception e, ForwardSocketClient client)? _onError;
  void Function(ForwardSocketClient client)? _onDone;
  bool? _cancelOnError;
  StreamSubscription<Uint8List>? _stream;
  final Lock _sendLock = Lock();
  Future<void>? _closingFuture;
  bool _disconnectNotified = false;

  int get port => _port;

  ForwardSocketClient._private(this.ip);

  static ForwardSocketClient empty = ForwardSocketClient._private("127.0.0.1");

  /// 建立可取消的中转控制 TCP 连接。
  static Future<ForwardSocketClient> connect({
    required String ip,
    required int port,
    void Function(ForwardSocketClient)? onConnected,
    void Function(ForwardSocketClient client, String data)? onMessage,
    void Function(Exception e, ForwardSocketClient client)? onError,
    void Function(ForwardSocketClient client)? onDone,
    bool? cancelOnError,
    CancelToken? cancelToken,
  }) async {
    final socket = await _connectSocket(
      ip: ip,
      port: port,
      cancelToken: cancelToken,
    );
    final client = ForwardSocketClient.fromSocket(
      socket: socket,
      onMessage: onMessage,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
    onConnected?.call(client);
    return client;
  }

  factory ForwardSocketClient.fromSocket({
    required Socket socket,
    int? serverPort,
    required void Function(ForwardSocketClient self, String data)? onMessage,
    void Function(Exception e, ForwardSocketClient self)? onError,
    void Function(ForwardSocketClient self)? onDone,
    bool? cancelOnError,
  }) {
    final client = ForwardSocketClient._private(socket.remoteAddress.address);
    client._port = serverPort ?? socket.remotePort;
    client._socket = socket;
    client._onMessage = onMessage;
    client._onError = onError;
    client._onDone = onDone;
    client._cancelOnError = cancelOnError;
    client._listen();
    return client;
  }

  static Future<Socket> _connectSocket({
    required String ip,
    required int port,
    CancelToken? cancelToken,
  }) async {
    final task = await Socket.startConnect(ip, port);
    Timer? cancelTimer;
    if (cancelToken != null) {
      cancelTimer = Timer.periodic(Constants.socketCancelPollInterval, (_) {
        if (cancelToken.isCanceled) {
          task.cancel();
        }
      });
    }
    try {
      if (cancelToken?.isCanceled ?? false) {
        task.cancel();
        throw SocketException("Forward Socket connection canceled: $ip:$port");
      }
      return await task.socket.timeout(
        Constants.socketConnectTimeout,
        onTimeout: () {
          task.cancel();
          throw SocketException("Forward Socket connection timed out: $ip:$port");
        },
      );
    } catch (_) {
      task.cancel();
      rethrow;
    } finally {
      cancelTimer?.cancel();
    }
  }

  /// 监听中转控制消息，错误和 EOF 只进入一次断线回调。
  void _listen() {
    if (_stream != null) {
      throw StateError("ForwardSocketClient has already started listening.");
    }
    _stream = _socket.transform(DataPacketSplitter()).listen(
      (bytes) {
        _onMessage?.call(this, utf8.decode(bytes));
      },
      onError: (Object error) {
        unawaited(_terminate(error: error, notify: true));
      },
      onDone: () {
        unawaited(_terminate(notify: true));
      },
      cancelOnError: _cancelOnError,
    );
  }

  /// 串行发送中转控制消息，发送失败统一收口为断线。
  void send(Map map) {
    unawaited(_send(map));
  }

  Future<void> _send(Map map) async {
    try {
      await _sendLock.synchronized(() async {
        final payload = utf8.encode(jsonEncode(map));
        final header = SecureSocketClient.createPacketHeader(
          payload.length,
          payload.length,
          1,
          1,
        );
        final packet = Uint8List(header.length + payload.length);
        packet.setAll(0, header);
        packet.setAll(header.length, payload);
        _socket.add(packet);
        await _socket.flush();
      });
    } catch (error) {
      await _terminate(error: error, notify: true);
    }
  }

  /// 主动关闭不触发自动重连回调，由上层控制连接监督器决定。
  Future<void> close() => _terminate(notify: false);

  Future<void> _terminate({Object? error, required bool notify}) {
    final closingFuture = _closingFuture;
    if (closingFuture != null) {
      return closingFuture;
    }
    final future = _closeAndNotify(error: error, notify: notify);
    _closingFuture = future;
    return future;
  }

  Future<void> _closeAndNotify({Object? error, required bool notify}) async {
    try {
      await _socket.close().timeout(Constants.socketGracefulCloseTimeout);
    } catch (_) {
      // 中转控制连接关闭必须兜底 destroy，避免网络切换后残留半开连接。
    } finally {
      try {
        await _stream?.cancel();
      } catch (_) {}
      _socket.destroy();
      if (notify) {
        _notifyDisconnected(error);
      }
    }
  }

  void _notifyDisconnected(Object? error) {
    if (_disconnectNotified) {
      return;
    }
    _disconnectNotified = true;
    if (error != null) {
      _onError?.call(error is Exception ? error : Exception(error.toString()), this);
    } else {
      _onDone?.call(this);
    }
  }
}
