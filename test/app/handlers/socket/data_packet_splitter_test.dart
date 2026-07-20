import 'dart:async';
import 'dart:typed_data';

import 'package:clipshare/app/handlers/socket/data_packet_splitter.dart';
import 'package:clipshare/app/handlers/socket/secure_socket_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DataPacketSplitter', () {
    test('parses a header and body split across arbitrary chunks', () async {
      final packet = _packet(<int>[1, 2, 3, 4], totalSize: 4);
      final chunks = <Uint8List>[
        packet.sublist(0, 3),
        packet.sublist(3, 9),
        packet.sublist(9, 11),
        packet.sublist(11),
      ];

      final messages = await Stream<Uint8List>.fromIterable(chunks)
          .transform(DataPacketSplitter())
          .toList();

      expect(messages, hasLength(1));
      expect(messages.single, <int>[1, 2, 3, 4]);
    });

    test('parses sticky packets containing multiple messages', () async {
      final first = _packet(<int>[1, 2], totalSize: 2);
      final second = _packet(<int>[3, 4, 5], totalSize: 3);
      final stickyChunk = Uint8List.fromList(<int>[...first, ...second]);

      final messages = await Stream<Uint8List>.value(stickyChunk)
          .transform(DataPacketSplitter())
          .toList();

      expect(messages, <List<int>>[
        <int>[1, 2],
        <int>[3, 4, 5],
      ]);
    });

    test('reassembles a large message from sequential packets', () async {
      final first = _packet(
        <int>[1, 2, 3],
        totalSize: 7,
        packetCount: 3,
        sequence: 1,
      );
      final second = _packet(
        <int>[4, 5],
        totalSize: 7,
        packetCount: 3,
        sequence: 2,
      );
      final third = _packet(
        <int>[6, 7],
        totalSize: 7,
        packetCount: 3,
        sequence: 3,
      );
      final bytes = Uint8List.fromList(<int>[...first, ...second, ...third]);
      final chunks = <Uint8List>[
        bytes.sublist(0, 12),
        bytes.sublist(12, 27),
        bytes.sublist(27),
      ];

      final messages = await Stream<Uint8List>.fromIterable(chunks)
          .transform(DataPacketSplitter())
          .toList();

      expect(messages.single, <int>[1, 2, 3, 4, 5, 6, 7]);
    });

    test('reports a residual packet when the stream ends', () async {
      final packet = _packet(<int>[1, 2, 3], totalSize: 3);
      final truncated = packet.sublist(0, packet.length - 1);

      expect(
        Stream<Uint8List>.value(truncated).transform(DataPacketSplitter()).toList(),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects an invalid packet sequence', () async {
      final packet = _packet(
        <int>[1],
        totalSize: 2,
        packetCount: 2,
        sequence: 2,
      );

      expect(
        Stream<Uint8List>.value(packet).transform(DataPacketSplitter()).toList(),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects a zero body length', () async {
      final header = SecureSocketClient.createPacketHeader(1, 0, 1, 1);

      expect(
        Stream<Uint8List>.value(header).transform(DataPacketSplitter()).toList(),
        throwsA(isA<FormatException>()),
      );
    });

    test('does not cancel the source subscription again after EOF', () async {
      final source = _CancelTrackingStream<Uint8List>(
        Stream<Uint8List>.value(_packet(<int>[1], totalSize: 1)),
      );

      final messages = await source.transform(DataPacketSplitter()).toList();

      expect(messages.single, <int>[1]);
      expect(source.cancelCount, 0);
    });
  });
}

/// 记录转换器是否在源流自然结束后仍显式取消订阅。
class _CancelTrackingStream<T> extends Stream<T> {
  final Stream<T> _delegate;
  int cancelCount = 0;

  _CancelTrackingStream(this._delegate);

  @override
  StreamSubscription<T> listen(
    void Function(T event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    final subscription = _delegate.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
    return _CancelTrackingSubscription<T>(subscription, () => cancelCount++);
  }
}

/// 代理真实订阅，仅拦截外部显式发起的取消操作。
class _CancelTrackingSubscription<T> implements StreamSubscription<T> {
  final StreamSubscription<T> _delegate;
  final void Function() _onCancel;

  _CancelTrackingSubscription(this._delegate, this._onCancel);

  @override
  Future<void> cancel() {
    _onCancel();
    return _delegate.cancel();
  }

  @override
  void onData(void Function(T data)? handleData) => _delegate.onData(handleData);

  @override
  void onError(Function? handleError) => _delegate.onError(handleError);

  @override
  void onDone(void Function()? handleDone) => _delegate.onDone(handleDone);

  @override
  void pause([Future<void>? resumeSignal]) => _delegate.pause(resumeSignal);

  @override
  void resume() => _delegate.resume();

  @override
  bool get isPaused => _delegate.isPaused;

  @override
  Future<E> asFuture<E>([E? futureValue]) => _delegate.asFuture<E>(futureValue);
}

/// 创建与线上协议完全一致的单个测试数据包。
Uint8List _packet(
  List<int> body, {
  required int totalSize,
  int packetCount = 1,
  int sequence = 1,
}) {
  final header = SecureSocketClient.createPacketHeader(
    totalSize,
    body.length,
    packetCount,
    sequence,
  );
  return Uint8List.fromList(<int>[...header, ...body]);
}
