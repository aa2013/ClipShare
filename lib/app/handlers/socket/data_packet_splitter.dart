import 'dart:async';
import 'dart:typed_data';

import 'package:clipshare/app/utils/constants.dart';

/// 按 10 字节包头协议还原完整 Socket 消息。
class DataPacketSplitter extends StreamTransformerBase<Uint8List, Uint8List> {
  @override
  Stream<Uint8List> bind(Stream<Uint8List> stream) {
    final parser = _DataPacketParser();
    late final StreamSubscription<Uint8List> subscription;
    late final StreamController<Uint8List> controller;
    var sourceTerminated = false;

    /// 解析失败时立即取消源流，避免错误连接继续占用 Socket。
    Future<void> closeWithError(Object error, StackTrace stackTrace) async {
      sourceTerminated = true;
      if (!controller.isClosed) {
        controller.addError(error, stackTrace);
      }
      await subscription.cancel();
      if (!controller.isClosed) {
        await controller.close();
      }
    }

    controller = StreamController<Uint8List>(
      sync: true,
      onListen: () {
        subscription = stream.listen(
          (chunk) {
            try {
              for (final message in parser.add(chunk)) {
                controller.add(message);
              }
            } catch (error, stackTrace) {
              unawaited(closeWithError(error, stackTrace));
            }
          },
          onError: (Object error, StackTrace stackTrace) {
            unawaited(closeWithError(error, stackTrace));
          },
          onDone: () async {
            sourceTerminated = true;
            try {
              parser.close();
            } catch (error, stackTrace) {
              if (!controller.isClosed) {
                controller.addError(error, stackTrace);
              }
            } finally {
              if (!controller.isClosed) {
                await controller.close();
              }
            }
          },
        );
      },
      onPause: () => subscription.pause(),
      onResume: () => subscription.resume(),
      onCancel: () {
        // 源流自然结束后不能重复取消；Windows Socket 的同步取消可能阻塞事件循环。
        if (sourceTerminated) return null;
        sourceTerminated = true;
        return subscription.cancel();
      },
    );
    return controller.stream;
  }
}

/// 保存单次绑定的解析状态，确保同一个 transformer 可安全复用。
class _DataPacketParser {
  final List<int> _input = <int>[];
  final BytesBuilder _message = BytesBuilder(copy: false);
  _PacketHeader? _currentHeader;
  int? _messageTotalSize;
  int? _messagePacketCount;
  int _expectedSequence = 1;

  /// 追加 TCP 字节并尽可能解析出完整消息。
  List<Uint8List> add(Uint8List chunk) {
    if (chunk.isEmpty) {
      return const <Uint8List>[];
    }
    _input.addAll(chunk);
    final messages = <Uint8List>[];

    while (true) {
      _currentHeader ??= _readHeader();
      final header = _currentHeader;
      if (header == null || _input.length < header.bodySize) {
        break;
      }

      final body = Uint8List.fromList(_input.sublist(0, header.bodySize));
      _input.removeRange(0, header.bodySize);
      _message.add(body);
      _currentHeader = null;

      if (header.sequence == header.packetCount) {
        final message = _message.takeBytes();
        if (message.length != header.totalSize) {
          _resetMessage();
          throw FormatException(
            'Socket message size ${message.length} does not match declared size ${header.totalSize}.',
          );
        }
        messages.add(message);
        _resetMessage();
      } else {
        _expectedSequence++;
      }
    }
    return messages;
  }

  /// 流结束时校验没有残留包头、包体或未完成消息。
  void close() {
    if (_input.isEmpty && _currentHeader == null && _message.length == 0) {
      return;
    }
    throw const FormatException('Socket stream ended with an incomplete packet.');
  }

  /// 在缓冲区足够时读取并校验一个包头。
  _PacketHeader? _readHeader() {
    if (_input.length < Constants.packetHeaderSize) {
      return null;
    }
    final bytes = Uint8List.fromList(_input.sublist(0, Constants.packetHeaderSize));
    _input.removeRange(0, Constants.packetHeaderSize);
    final data = ByteData.sublistView(bytes);
    final header = _PacketHeader(
      totalSize: data.getUint32(0, Endian.big),
      bodySize: data.getUint16(4, Endian.big),
      packetCount: data.getUint16(6, Endian.big),
      sequence: data.getUint16(8, Endian.big),
    );
    _validateHeader(header);
    return header;
  }

  /// 校验包序号及同一消息内不应变化的声明字段。
  void _validateHeader(_PacketHeader header) {
    if (header.totalSize <= 0 || header.bodySize <= 0 || header.packetCount <= 0) {
      throw const FormatException('Socket packet contains a non-positive size or packet count.');
    }
    if (header.sequence <= 0 || header.sequence > header.packetCount) {
      throw FormatException(
        'Socket packet sequence ${header.sequence} is outside 1..${header.packetCount}.',
      );
    }
    if (header.sequence != _expectedSequence) {
      throw FormatException(
        'Socket packet sequence ${header.sequence} does not match expected $_expectedSequence.',
      );
    }
    if (header.sequence == 1) {
      if (_message.length != 0) {
        throw const FormatException('A new Socket message started before the previous message completed.');
      }
      _messageTotalSize = header.totalSize;
      _messagePacketCount = header.packetCount;
    } else if (header.totalSize != _messageTotalSize || header.packetCount != _messagePacketCount) {
      throw const FormatException('Socket packet metadata changed within one message.');
    }
    if (header.bodySize > header.totalSize || _message.length + header.bodySize > header.totalSize) {
      throw const FormatException('Socket packet body exceeds the declared message size.');
    }
  }

  /// 完整消息输出后恢复下一条消息的初始状态。
  void _resetMessage() {
    _message.takeBytes();
    _messageTotalSize = null;
    _messagePacketCount = null;
    _expectedSequence = 1;
  }
}

/// 既有 Socket 包头字段的内部表示。
class _PacketHeader {
  final int totalSize;
  final int bodySize;
  final int packetCount;
  final int sequence;

  const _PacketHeader({
    required this.totalSize,
    required this.bodySize,
    required this.packetCount,
    required this.sequence,
  });
}
