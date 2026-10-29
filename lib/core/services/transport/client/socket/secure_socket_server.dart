import 'dart:async';
import 'dart:io';

import 'package:clipshare/core/database/app_database.dart';
import 'package:clipshare/core/services/transport/models/local_socket_base_info.dart';
import 'package:clipshare/shared/utils/log.dart';

import 'secure_socket_client.dart';

class SecureSocketServer {
  static const tag = 'SecureSocketServer';

  final String ip;
  final int port;
  late final ServerSocket _server;
  late final LocalSocketBaseInfo _baseInfo;
  late final Device? Function(String guid) _loadDevice;
  late final void Function(String ip, int port) _onConnected;
  late final void Function(SecureSocketClient client, Map<String, dynamic> data) _onMessage;
  void Function(SecureSocketClient client)? _onClientReady;
  Function? _onError;
  void Function(
    Exception e,
    String ip,
    int port,
    SecureSocketClient client,
  )?
  _onClientError;
  void Function(
    String ip,
    int port,
    SecureSocketClient client,
  )?
  _onClientDone;
  void Function()? _onDone;
  bool? _cancelOnError;
  StreamSubscription<Socket>? _stream;
  final Set<SecureSocketClient> _clients = <SecureSocketClient>{};
  Future<void>? _closingFuture;

  SecureSocketServer._private(this.ip, this.port);

  /// 服务端绑定监听端口，并等待每个入站连接完成设备级握手后再通知上层。
  static Future<SecureSocketServer> bind({
    required String ip,
    required int port,
    required LocalSocketBaseInfo baseInfo,
    required Device? Function(String guid) loadDevice,
    required void Function(String ip, int port) onConnected,
    required void Function(SecureSocketClient client, Map<String, dynamic> data) onMessage,
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
    void Function(Exception e, String ip, int port, SecureSocketClient client)? onClientError,
    void Function(String ip, int port, SecureSocketClient client)? onClientDone,
    void Function(SecureSocketClient client)? onClientReady,
  }) async {
    final server = SecureSocketServer._private(ip, port);
    server._baseInfo = baseInfo;
    server._loadDevice = loadDevice;
    server._server = await ServerSocket.bind(ip, port, shared: true);
    server._onMessage = onMessage;
    server._onError = onError;
    server._onConnected = onConnected;
    server._onDone = onDone;
    server._onClientDone = onClientDone;
    server._onClientError = onClientError;
    server._onClientReady = onClientReady;
    server._cancelOnError = cancelOnError;
    server._listen();
    return server;
  }

  void _listen() {
    if (_stream != null) {
      throw StateError('SecureSocketServer has already started listening.');
    }
    _stream = _server.listen(
      (socket) {
        unawaited(_handleAcceptedSocket(socket));
      },
      onError: (Object error, StackTrace stackTrace) {
        logger.error(tag, 'Socket server failed: $error', stackTrace);
        _onError?.call(error);
      },
      onDone: () {
        _onDone?.call();
      },
      cancelOnError: _cancelOnError,
    );
  }

  Future<void> _handleAcceptedSocket(Socket socket) async {
    final remoteIp = socket.remoteAddress.address;
    final remotePort = socket.remotePort;
    late final SecureSocketClient client;
    client = SecureSocketClient.fromSocket(
      socket: socket,
      localBaseInfo: _baseInfo,
      onMessage: _onMessage,
      loadDevice: _loadDevice,
      onDone: (closedClient) {
        _clients.remove(closedClient);
        _onClientDone?.call(remoteIp, remotePort, closedClient);
      },
      onError: (error, failedClient) {
        _clients.remove(failedClient);
        logger.error(tag, 'Accepted Socket failed: $error');
        _onClientError?.call(error, remoteIp, remotePort, failedClient);
      },
      cancelOnError: _cancelOnError,
    );
    _clients.add(client);
    try {
      await client.waitReady();
      _onConnected(client.ip, client.port);
      _onClientReady?.call(client);
    } catch (error, stackTrace) {
      _clients.remove(client);
      logger.debug(tag, 'Accepted Socket closed before ready: $error $stackTrace');
      _onClientError?.call(
        error is Exception ? error : Exception(error.toString()),
        remoteIp,
        remotePort,
        client,
      );
      await client.close();
    }
  }

  /// 通过服务端持有的当前客户端发送一条消息。
  Future<void> send(SecureSocketClient client, Map map) async {
    await client.send(map);
  }

  /// 关闭监听端口和所有已接入客户端，避免服务停止后残留连接。
  Future<void> close() {
    final closingFuture = _closingFuture;
    if (closingFuture != null) {
      return closingFuture;
    }
    final future = _close();
    _closingFuture = future;
    return future;
  }

  Future<void> _close() async {
    final clients = _clients.toList(growable: false);
    _clients.clear();
    try {
      await _stream?.cancel();
    } catch (_) {}
    await _server.close();
    for (final client in clients) {
      await client.close();
    }
  }
}
