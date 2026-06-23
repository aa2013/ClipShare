import 'dart:async';
import 'dart:io';

/// 本地真实 WebSocket 会话，供存储服务测试观察连接与主动发消息。
class TestStorageWsSession {
  final WebSocket socket;

  TestStorageWsSession(this.socket);

  Future<void> close([int? closeCode, String? closeReason]) {
    return socket.close(closeCode, closeReason);
  }

  Future<void> send(String message) {
    socket.add(message);
    return Future<void>.value();
  }
}

/// 复用的本地 WebSocket 服务端，便于不同存储测试走真实握手和消息流。
class TestStorageWsServer {
  late final HttpServer _server;
  final List<TestStorageWsSession> sessions = <TestStorageWsSession>[];
  final StreamController<String> receivedMessages = StreamController<String>.broadcast();
  final StreamController<TestStorageWsSession> acceptedSessions = StreamController<TestStorageWsSession>.broadcast();

  Uri get uri => Uri.parse('ws://127.0.0.1:${_server.port}');

  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server.listen((HttpRequest request) async {
      if (!request.uri.path.startsWith('/connect/')) {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
        return;
      }
      final socket = await WebSocketTransformer.upgrade(request);
      final session = TestStorageWsSession(socket);
      sessions.add(session);
      acceptedSessions.add(session);
      socket.listen(
        (dynamic data) {
          receivedMessages.add(data.toString());
        },
        onDone: () {
          sessions.remove(session);
        },
        onError: (_) {
          sessions.remove(session);
        },
      );
    });
  }

  Future<void> dispose() async {
    for (final session in List<TestStorageWsSession>.from(sessions)) {
      await session.close();
    }
    await _server.close(force: true);
    await receivedMessages.close();
    await acceptedSessions.close();
  }
}
