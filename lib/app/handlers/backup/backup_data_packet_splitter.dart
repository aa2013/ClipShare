import 'dart:async';
import 'dart:typed_data';
import 'dart:math';

class BackupDataPacketSplitter extends StreamTransformerBase<List<int>, Uint8List> {
  final Endian endian;
  final int headerLen;

  BackupDataPacketSplitter({
    this.endian = Endian.little,
    this.headerLen = 4,
  }) {
    if (headerLen <= 0) throw ArgumentError.value(headerLen, 'headerLen', 'must be > 0');
  }

  @override
  Stream<Uint8List> bind(Stream<List<int>> stream) async* {
    // 累积未处理的字节
    final readBuffer = <int>[];
    // 当前包体预期长度（null 表示还没读到完整 header）
    int? pkgSize;

    await for (final chunk in stream) {
      if (chunk.isEmpty) continue;
      readBuffer.addAll(chunk);

      // 尽可能多地从缓冲区里取出完整包（支持一个 chunk 含多包）
      while (true) {
        // 1) 如果还没读到 header，尝试读 header
        if (pkgSize == null) {
          if (readBuffer.length < headerLen) {
            // header 不完整，等待下一个 chunk
            break;
          }
          // 读取 header（拷贝 header bytes）
          final headerBytes = Uint8List.fromList(readBuffer.sublist(0, headerLen));
          final headerView = ByteData.sublistView(headerBytes);
          final size = headerView.getUint32(0, endian);
          if (size < 0) {
            throw StateError('Invalid packet size: $size');
          }
          pkgSize = size;
          // 移除 header bytes
          readBuffer.removeRange(0, headerLen);
        }

        // 2) 如果已经知道预期长度，检查缓冲是否有足够包体
        if (pkgSize != null) {
          if (readBuffer.length < pkgSize) {
            // 包体不完整，等待下一个 chunk
            break;
          }
          // 有完整的包体
          final payload = Uint8List.fromList(readBuffer.sublist(0, pkgSize));
          yield payload;
          // 移除已输出的包体
          readBuffer.removeRange(0, pkgSize);
          // 重置期待值，准备下一个包
          pkgSize = null;
          // 继续 while 循环，可能还有下一个包
          continue;
        }
        break;
      }
    }

    // 上游结束（onDone）后：如果缓冲区仍有数据，说明有不完整包
    if (pkgSize != null || readBuffer.isNotEmpty) {
      throw StateError(
        'Stream ended with incomplete packet. '
            'pkgSize=$pkgSize, remainingBytes=${readBuffer.length}',
      );
    }
  }
}
