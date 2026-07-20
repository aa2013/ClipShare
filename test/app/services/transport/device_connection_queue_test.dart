import 'dart:async';
import 'dart:io';

import 'package:clipshare/app/data/models/dev_info.dart';
import 'package:clipshare/app/data/models/version.dart';
import 'package:clipshare/app/handlers/socket/secure_socket_client.dart';
import 'package:clipshare/app/services/transport/device_connection_queue.dart';
import 'package:clipshare/app/services/transport/device_socket_session_store.dart';
import 'package:clipshare/app/utils/parallerl_task.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DeviceConnectionQueue', () {
    test('同设备请求按提交顺序串行处理', () async {
      final releaseFirst = Completer<void>();
      final events = <String>[];
      final queue = DeviceConnectionQueue(
        idleTtl: const Duration(milliseconds: 20),
        processor: (request) async {
          events.add('start:${request.description}');
          if (request.description == 'first') {
            await releaseFirst.future;
          }
          events.add('end:${request.description}');
          return true;
        },
      );
      addTearDown(queue.close);

      final first = queue.enqueue(_request('dev-a', 'first'));
      await Future<void>.delayed(Duration.zero);
      final second = queue.enqueue(_request('dev-a', 'second'));

      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(events, <String>['start:first']);

      releaseFirst.complete();
      expect(await first, isTrue);
      expect(await second, isTrue);
      expect(events, <String>[
        'start:first',
        'end:first',
        'start:second',
        'end:second',
      ]);
    });

    test('不同设备请求不会互相阻塞', () async {
      final releaseA = Completer<void>();
      final events = <String>[];
      final queue = DeviceConnectionQueue(
        idleTtl: const Duration(milliseconds: 20),
        processor: (request) async {
          events.add('start:${request.workerKey}');
          if (request.workerKey == 'dev-a') {
            await releaseA.future;
          }
          events.add('end:${request.workerKey}');
          return true;
        },
      );
      addTearDown(queue.close);

      final first = queue.enqueue(_request('dev-a', 'first'));
      await Future<void>.delayed(Duration.zero);
      final second = queue.enqueue(_request('dev-b', 'second'));

      expect(await second.timeout(const Duration(seconds: 1)), isTrue);
      expect(events, containsAllInOrder(<String>['start:dev-a', 'start:dev-b', 'end:dev-b']));

      releaseA.complete();
      expect(await first, isTrue);
      expect(events.last, 'end:dev-a');
    });

    test('已取消请求不会进入处理器', () async {
      final tokenSource = CancelTokenSource()..cancel();
      var calls = 0;
      final queue = DeviceConnectionQueue(
        processor: (_) async {
          calls++;
          return true;
        },
      );
      addTearDown(queue.close);

      final result = await queue.enqueue(_request('dev-a', 'canceled', token: tokenSource.token));

      expect(result, isFalse);
      expect(calls, 0);
    });
  });

  group('DeviceSocketSessionStore', () {
    test('按 devId 覆盖会话，并用 client identity 安全删除', () async {
      final firstPair = await _SocketClientPair.create();
      final secondPair = await _SocketClientPair.create();
      addTearDown(firstPair.close);
      addTearDown(secondPair.close);

      final store = DeviceSocketSessionStore();
      final firstDev = DevInfo('dev-a', 'first', 'desktop');
      final secondDev = DevInfo('dev-a', 'second', 'desktop');
      const version = AppVersion('1.0.0', '1');

      store.put(DeviceSocketSession(
        dev: firstDev,
        socket: firstPair.client,
        isPaired: true,
        minVersion: version,
        version: version,
      ));
      store.put(DeviceSocketSession(
        dev: secondDev,
        socket: secondPair.client,
        isPaired: false,
        minVersion: version,
        version: version,
      ));

      expect(store.snapshot(), hasLength(1));
      expect(store.get('dev-a')?.dev.name, 'second');
      expect(store.removeIfCurrent('dev-a', firstPair.client), isNull);

      final removed = store.removeIfCurrent('dev-a', secondPair.client);
      expect(removed?.dev.name, 'second');
      expect(store.get('dev-a'), isNull);
    });
  });
}

DeviceConnectionRequest _request(
  String workerKey,
  String description, {
  CancelToken? token,
}) {
  return DeviceConnectionRequest(
    workerKey: workerKey,
    description: description,
    token: token ?? CancelToken.none,
    connect: (_) => throw StateError('测试处理器不会创建真实 Socket'),
  );
}

class _SocketClientPair {
  final ServerSocket server;
  final SecureSocketClient client;
  final SecureSocketClient peer;

  _SocketClientPair({
    required this.server,
    required this.client,
    required this.peer,
  });

  /// 创建本地回环连接对，只用于提供两个不同的 SecureSocketClient identity。
  static Future<_SocketClientPair> create() async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final acceptedFuture = server.first;
    final socket = await Socket.connect(InternetAddress.loopbackIPv4, server.port);
    final accepted = await acceptedFuture;
    final client = _wrapSocket(socket);
    final peer = _wrapSocket(accepted);
    return _SocketClientPair(server: server, client: client, peer: peer);
  }

  Future<void> close() async {
    await client.close();
    await peer.close();
    await server.close();
  }

  static SecureSocketClient _wrapSocket(Socket socket) {
    final client = SecureSocketClient.fromSocket(
      socket: socket,
      prime1: BigInt.from(23),
      prime2: BigInt.from(5),
      dhAesKey: null,
      onMessage: (_, __) {},
    );
    // 测试只需要 client identity；消费未握手关闭的 ready 错误，避免测试区捕获异步异常。
    unawaited(client.waitReady().catchError((_) => client));
    return client;
  }
}