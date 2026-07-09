import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:clipshare/app/data/models/websocket/ws_msg_data.dart';
import 'package:clipshare/app/data/models/websocket/ws_msg_type.dart';

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
  final bool respondToPing;

  late final HttpServer _server;
  final List<TestStorageWsSession> sessions = <TestStorageWsSession>[];
  final StreamController<String> receivedMessages = StreamController<String>.broadcast();
  final StreamController<TestStorageWsSession> acceptedSessions = StreamController<TestStorageWsSession>.broadcast();

  TestStorageWsServer({
    this.respondToPing = false,
  });

  Uri get uri => Uri.parse('ws://127.0.0.1:${_server.port}');

  /// 启动测试用 WebSocket 服务端，可按需模拟通知服务是否返回 ping 确认。
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
          final message = data.toString();
          receivedMessages.add(message);
          _respondPingIfNeeded(socket, message);
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

  /// 按配置返回 ping 确认，用于覆盖半开连接检测和正常保活两类测试场景。
  void _respondPingIfNeeded(WebSocket socket, String message) {
    if (!respondToPing) {
      return;
    }
    try {
      final wsMessage = WsMsgData.fromJson((jsonDecode(message) as Map<dynamic, dynamic>).cast<String, dynamic>());
      if (wsMessage.operation != WsMsgType.ping) {
        return;
      }
      socket.add(jsonEncode(WsMsgData(WsMsgType.ping, '', wsMessage.targetDevId)));
    } catch (_) {
      // 测试服务端只关心合法 ping，其他异常输入交给被测逻辑自行处理。
    }
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
