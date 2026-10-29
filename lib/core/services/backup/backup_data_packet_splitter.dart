import 'dart:async';
import 'dart:typed_data';

/// 备份数据包切包器，解析 `[headerLen 字节长度头][包体]` 格式的字节流
class BackupDataPacketSplitter extends StreamTransformerBase<List<int>, Uint8List> {
  final Endian endian;
  final int headerLen;

  BackupDataPacketSplitter({
    this.endian = Endian.little,
    this.headerLen = 4,
  }) {
    if (headerLen <= 0) {
      throw ArgumentError.value(headerLen, 'headerLen', 'must be > 0');
    }
  }

  @override
  Stream<Uint8List> bind(Stream<List<int>> stream) async* {
    // 累积未处理的字节
    final readBuffer = <int>[];
    // 当前包体预期长度（null 表示还没读到完整 header）
    int? pkgSize;

    await for (final chunk in stream) {
      if (chunk.isEmpty) {
        continue;
      }
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
          pkgSize = headerView.getUint32(0, endian);
          // 移除 header bytes
          readBuffer.removeRange(0, headerLen);
        }

        // 2) 包体长度已知，检查缓冲是否有足够包体
        final expectedSize = pkgSize;
        if (readBuffer.length < expectedSize) {
          // 包体不完整，等待下一个 chunk
          break;
        }
        // 有完整的包体
        final payload = Uint8List.fromList(readBuffer.sublist(0, expectedSize));
        yield payload;
        // 移除已输出的包体，重置期待值准备下一个包
        readBuffer.removeRange(0, expectedSize);
        pkgSize = null;
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
