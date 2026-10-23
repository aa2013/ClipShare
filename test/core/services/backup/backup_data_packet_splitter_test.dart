import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:clipshare/core/services/backup/backup_data_packet_splitter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// 构造一个数据包：4 字节小端长度头 + 包体
  Uint8List buildPacket(Uint8List payload) {
    final bytes = Uint8List(4 + payload.length);
    final byteData = ByteData.sublistView(bytes);
    byteData.setUint32(0, payload.length, Endian.little);
    bytes.setAll(4, payload);
    return bytes;
  }

  Uint8List payload(String text) => Uint8List.fromList(utf8.encode(text));

  group('BackupDataPacketSplitter', () {
    test('emits a single packet received in one chunk', () async {
      final splitter = BackupDataPacketSplitter();
      final input = Stream<List<int>>.value(buildPacket(payload('hello')));
      final packets = await splitter.bind(input).toList();
      expect(packets, hasLength(1));
      expect(utf8.decode(packets[0]), 'hello');
    });

    test('emits multiple packets contained in one chunk', () async {
      final splitter = BackupDataPacketSplitter();
      final chunk = [...buildPacket(payload('a')), ...buildPacket(payload('bb')), ...buildPacket(payload('ccc'))];
      final input = Stream<List<int>>.value(chunk);
      final packets = await splitter.bind(input).toList();
      expect(packets.map(utf8.decode), ['a', 'bb', 'ccc']);
    });

    test('reassembles a packet split across chunks', () async {
      final splitter = BackupDataPacketSplitter();
      final packet = buildPacket(payload('cross-chunk payload'));
      final controller = StreamController<List<int>>();
      final collect = splitter.bind(controller.stream).toList();
      // 分三段投递：半个 header、header 剩余与部分包体、包体剩余
      controller.add(packet.sublist(0, 2));
      controller.add(packet.sublist(2, 10));
      controller.add(packet.sublist(10));
      await controller.close();
      final packets = await collect;
      expect(packets, hasLength(1));
      expect(utf8.decode(packets[0]), 'cross-chunk payload');
    });

    test('handles header and payload split at the exact boundary', () async {
      final splitter = BackupDataPacketSplitter();
      final packet = buildPacket(payload('body'));
      final controller = StreamController<List<int>>();
      final collect = splitter.bind(controller.stream).toList();
      controller.add(packet.sublist(0, 4));
      controller.add(packet.sublist(4));
      await controller.close();
      final packets = await collect;
      expect(packets, hasLength(1));
      expect(utf8.decode(packets[0]), 'body');
    });

    test('throws StateError when the stream ends with an incomplete packet', () async {
      final splitter = BackupDataPacketSplitter();
      final packet = buildPacket(payload('incomplete'));
      final input = Stream<List<int>>.value(packet.sublist(0, 4 + 5));
      await expectLater(splitter.bind(input).toList(), throwsStateError);
    });

    test('throws StateError when the stream ends with a bare header', () async {
      final splitter = BackupDataPacketSplitter();
      final packet = buildPacket(payload('data'));
      final input = Stream<List<int>>.value(packet.sublist(0, 4));
      await expectLater(splitter.bind(input).toList(), throwsStateError);
    });

    test('throws ArgumentError for non-positive headerLen', () {
      expect(() => BackupDataPacketSplitter(headerLen: 0), throwsArgumentError);
      expect(() => BackupDataPacketSplitter(headerLen: -1), throwsArgumentError);
    });

    test('parses big endian packets when configured', () async {
      final splitter = BackupDataPacketSplitter(endian: Endian.big);
      final payloadBytes = payload('big-endian');
      final bytes = Uint8List(4 + payloadBytes.length);
      final byteData = ByteData.sublistView(bytes);
      byteData.setUint32(0, payloadBytes.length, Endian.big);
      bytes.setAll(4, payloadBytes);
      final input = Stream<List<int>>.value(bytes);
      final packets = await splitter.bind(input).toList();
      expect(packets, hasLength(1));
      expect(utf8.decode(packets[0]), 'big-endian');
    });
  });
}
