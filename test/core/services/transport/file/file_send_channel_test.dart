import 'dart:async';
import 'dart:io';

import 'package:clipshare/core/services/transport/file/sender/file_send_channel.dart';
import 'package:clipshare/shared/utils/parallerl_task.dart';
import 'package:flutter_test/flutter_test.dart';

Stream<List<int>> _byteStream(List<List<int>> chunks) async* {
  for (final chunk in chunks) {
    yield chunk;
  }
}

void main() {
  group('trackFileStream', () {
    test('统计累计进度并透传字节', () async {
      final source = _byteStream([
        [1, 2, 3],
        [4, 5],
      ]);
      final received = <int>[];
      final progress = <int>[];
      final tracked = trackFileStream(
        source,
        cancelToken: CancelToken(),
        onProgress: progress.add,
      );
      await for (final chunk in tracked) {
        received.addAll(chunk);
      }
      expect(received, [1, 2, 3, 4, 5]);
      expect(progress, [3, 5]);
    });

    test('取消令牌生效后流以取消异常结束且不再透传', () async {
      final controller = StreamController<List<int>>();
      final tokenSource = CancelTokenSource();
      final progress = <int>[];
      final tracked = trackFileStream(
        controller.stream,
        cancelToken: tokenSource.token,
        onProgress: progress.add,
      );
      final done = expectLater(tracked.drain<void>(), throwsA(isA<FileTransferCanceledException>()));
      controller.add([1, 1, 1]);
      await Future<void>.delayed(Duration.zero);
      tokenSource.cancel();
      //取消后需要新的数据事件触发检查才会中断
      controller.add([2, 2]);
      await controller.close();
      await done;
      expect(progress, [3]);
    });
  });

  group('openSendSourceStream', () {
    test('本地文件按字节流读取', () async {
      final tempDir = await Directory.systemTemp.createTemp('clipshare_file_test');
      final file = File('${tempDir.path}/a.bin');
      await file.writeAsBytes([7, 8, 9]);
      addTearDown(() async => tempDir.delete(recursive: true));

      final stream = await openSendSourceStream(file.path, isUri: false);
      final bytes = <int>[];
      await for (final chunk in stream) {
        bytes.addAll(chunk);
      }
      expect(bytes, [7, 8, 9]);
    });
  });
}
