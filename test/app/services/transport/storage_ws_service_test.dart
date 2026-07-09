import 'dart:async';
import 'dart:io';

import 'package:clipshare/app/data/models/websocket/ws_msg_data.dart';
import 'package:clipshare/app/data/models/websocket/ws_msg_type.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/transport/storage_ws_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'test_storage_ws_server.dart';

/// 手动控制 ready 完成时机的包装通道，用来覆盖“旧会话 ready 晚到”的竞态场景。
class _DelayedReadyWebSocketChannel with StreamChannelMixin implements WebSocketChannel {
  final WebSocketChannel _delegate;
  final Completer<void> _readyCompleter = Completer<void>();

  _DelayedReadyWebSocketChannel(this._delegate) {
    _delegate.ready.then((_) {
      if (!_readyCompleter.isCompleted) {
        _readyCompleter.complete();
      }
    }).catchError((Object err, StackTrace stack) {
      if (!_readyCompleter.isCompleted) {
        _readyCompleter.completeError(err, stack);
      }
    });
  }

  void releaseReady() {
    if (!_readyCompleter.isCompleted) {
      _readyCompleter.complete();
    }
  }

  @override
  int? get closeCode => _delegate.closeCode;

  @override
  String? get closeReason => _delegate.closeReason;

  @override
  String? get protocol => _delegate.protocol;

  @override
  Future<void> get ready => _readyCompleter.future;

  @override
  WebSocketSink get sink => _delegate.sink;

  @override
  Stream get stream => _delegate.stream;
}

void main() {
  group('StorageWsService', () {
    late TestStorageWsServer server;

    setUp(() async {
      Get.testMode = true;
      if (!Get.isRegistered<ConfigService>()) {
        Get.put(ConfigService());
      }
      server = TestStorageWsServer();
      await server.start();
    });

    tearDown(() async {
      await server.dispose();
      Get.reset();
    });

    test('首次连接成功后状态流为 connecting -> connected', () async {
      final statuses = <StorageWsStatus>[];
      final service = StorageWsService(
        connectUriBuilder: () => server.uri.replace(path: '/connect/test-dev'),
        shouldKeepConnected: () => true,
        pingInterval: const Duration(hours: 1),
        reconnectDelay: const Duration(milliseconds: 100),
      );
      final sub = service.statusStream.listen(statuses.add);

      await service.connect();
      await server.acceptedSessions.stream.first;
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(statuses, <StorageWsStatus>[
        StorageWsStatus.connecting,
        StorageWsStatus.connected,
      ]);

      await sub.cancel();
      await service.dispose();
    });

    test('服务端主动关闭连接后会自动重连并更新状态', () async {
      final statuses = <StorageWsStatus>[];
      final service = StorageWsService(
        connectUriBuilder: () => server.uri.replace(path: '/connect/test-dev'),
        shouldKeepConnected: () => true,
        pingInterval: const Duration(hours: 1),
        reconnectDelay: const Duration(milliseconds: 100),
      );
      final sub = service.statusStream.listen(statuses.add);

      await service.connect();
      final firstSession = await server.acceptedSessions.stream.first;
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await firstSession.close(WebSocketStatus.normalClosure, 'close for reconnect');

      await Future<void>.delayed(const Duration(milliseconds: 250));

      expect(
        statuses,
        <StorageWsStatus>[
          StorageWsStatus.connecting,
          StorageWsStatus.connected,
          StorageWsStatus.disconnected,
          StorageWsStatus.connecting,
          StorageWsStatus.connected,
        ],
      );
      expect(server.sessions, isNotEmpty);

      await sub.cancel();
      await service.dispose();
    });

    test('手动 disconnect 后不继续自动重连', () async {
      final statuses = <StorageWsStatus>[];
      final service = StorageWsService(
        connectUriBuilder: () => server.uri.replace(path: '/connect/test-dev'),
        shouldKeepConnected: () => true,
        pingInterval: const Duration(hours: 1),
        reconnectDelay: const Duration(milliseconds: 100),
      );
      final sub = service.statusStream.listen(statuses.add);

      await service.connect();
      await server.acceptedSessions.stream.first;
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await service.disconnect();

      await Future<void>.delayed(const Duration(milliseconds: 250));

      expect(
        statuses,
        <StorageWsStatus>[
          StorageWsStatus.connecting,
          StorageWsStatus.connected,
          StorageWsStatus.disconnected,
        ],
      );
      expect(server.sessions, isEmpty);

      await sub.cancel();
      await service.dispose();
    });

    test('发送消息时底层关闭会进入断线收口并触发重连', () async {
      final statuses = <StorageWsStatus>[];
      final service = StorageWsService(
        connectUriBuilder: () => server.uri.replace(path: '/connect/test-dev'),
        shouldKeepConnected: () => true,
        pingInterval: const Duration(hours: 1),
        reconnectDelay: const Duration(milliseconds: 100),
      );
      final sub = service.statusStream.listen(statuses.add);

      await service.connect();
      final firstSession = await server.acceptedSessions.stream.first;
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await firstSession.close(WebSocketStatus.goingAway, 'drop before send');
      await Future<void>.delayed(const Duration(milliseconds: 30));

      service.send(WsMsgData(WsMsgType.change, '2026-06-28:1', 'peer-dev'));
      await Future<void>.delayed(const Duration(milliseconds: 250));

      expect(statuses.contains(StorageWsStatus.disconnected), isTrue);
      expect(statuses.takeLast(2), <StorageWsStatus>[
        StorageWsStatus.connecting,
        StorageWsStatus.connected,
      ]);

      await sub.cancel();
      await service.dispose();
    });

    test('旧会话 ready 晚到时不会留下第二条脱管连接', () async {
      final delayedChannels = <_DelayedReadyWebSocketChannel>[];
      final service = StorageWsService(
        connectUriBuilder: () => server.uri.replace(path: '/connect/test-dev'),
        shouldKeepConnected: () => true,
        pingInterval: const Duration(hours: 1),
        reconnectDelay: const Duration(milliseconds: 100),
        connectFactory: (uri) {
          final delayedChannel = _DelayedReadyWebSocketChannel(IOWebSocketChannel.connect(uri));
          delayedChannels.add(delayedChannel);
          return delayedChannel;
        },
      );

      unawaited(service.connect());
      final firstSession = await server.acceptedSessions.stream.first;
      expect(server.sessions.length, 1);

      await service.disconnect();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(server.sessions, isEmpty);

      await service.connect();
      final secondSession = await server.acceptedSessions.stream.first;
      expect(server.sessions.length, 1);

      delayedChannels.first.releaseReady();
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(server.sessions.length, 1);
      expect(server.sessions.single, same(secondSession));

      await secondSession.close();
      await service.dispose();
      await firstSession.close();
    });

    test('服务端不响应 ping 时会按心跳超时断开并自动重连', () async {
      final statuses = <StorageWsStatus>[];
      final service = StorageWsService(
        connectUriBuilder: () => server.uri.replace(path: '/connect/test-dev'),
        shouldKeepConnected: () => true,
        pingInterval: const Duration(milliseconds: 30),
        pingTimeout: const Duration(milliseconds: 80),
        reconnectDelay: const Duration(milliseconds: 50),
      );
      final sub = service.statusStream.listen(statuses.add);

      await service.connect();
      await server.acceptedSessions.stream.first;

      await Future<void>.delayed(const Duration(milliseconds: 180));

      expect(statuses.contains(StorageWsStatus.disconnected), isTrue);
      expect(statuses.takeLast(2), <StorageWsStatus>[
        StorageWsStatus.connecting,
        StorageWsStatus.connected,
      ]);

      await sub.cancel();
      await service.dispose();
    });

    test('服务端响应 ping 时保持连接且不误触发重连', () async {
      await server.dispose();
      server = TestStorageWsServer(respondToPing: true);
      await server.start();
      final statuses = <StorageWsStatus>[];
      final service = StorageWsService(
        connectUriBuilder: () => server.uri.replace(path: '/connect/test-dev'),
        shouldKeepConnected: () => true,
        pingInterval: const Duration(milliseconds: 30),
        pingTimeout: const Duration(milliseconds: 80),
        reconnectDelay: const Duration(milliseconds: 50),
      );
      final sub = service.statusStream.listen(statuses.add);

      await service.connect();
      await server.acceptedSessions.stream.first;

      await Future<void>.delayed(const Duration(milliseconds: 180));

      expect(statuses, <StorageWsStatus>[
        StorageWsStatus.connecting,
        StorageWsStatus.connected,
      ]);
      expect(server.sessions.length, 1);

      await sub.cancel();
      await service.dispose();
    });

    test('收到 ping 确认只刷新心跳，不分发给业务消息监听', () async {
      await server.dispose();
      server = TestStorageWsServer(respondToPing: true);
      await server.start();
      final messages = <WsMsgData>[];
      final service = StorageWsService(
        connectUriBuilder: () => server.uri.replace(path: '/connect/test-dev'),
        shouldKeepConnected: () => true,
        pingInterval: const Duration(milliseconds: 30),
        pingTimeout: const Duration(milliseconds: 80),
        reconnectDelay: const Duration(milliseconds: 50),
        onMessage: messages.add,
      );

      await service.connect();
      await server.acceptedSessions.stream.first;

      await Future<void>.delayed(const Duration(milliseconds: 90));

      expect(messages, isEmpty);

      await service.dispose();
    });
  });
}

extension on List<StorageWsStatus> {
  List<StorageWsStatus> takeLast(int count) {
    if (length <= count) {
      return List<StorageWsStatus>.from(this);
    }
    return sublist(length - count);
  }
}
