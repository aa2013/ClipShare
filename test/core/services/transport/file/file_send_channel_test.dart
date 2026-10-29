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
    test('accumulates progress and passes bytes through', () async {
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

    test('ends the stream right after cancel without new data events', () async {
      final controller = StreamController<List<int>>();
      final tokenSource = CancelTokenSource();
      final progress = <int>[];
      final tracked = trackFileStream(
        controller.stream,
        cancelToken: tokenSource.token,
        onProgress: progress.add,
      );
      final received = <List<int>>[];
      final errors = <Object>[];
      final done = Completer<void>();
      tracked.listen(
        received.add,
        onError: errors.add,
        onDone: () {
          if (!done.isCompleted) {
            done.complete();
          }
        },
      );
      controller.add([1, 1, 1]);
      await Future<void>.delayed(Duration.zero);

      tokenSource.cancel();
      await done.future;

      expect(received, [
        [1, 1, 1],
      ]);
      expect(errors.single, isA<FileTransferCanceledException>());
      expect(progress, [3]);
      await controller.close();
    });

    test('passes bytes through when progress is omitted', () async {
      final source = _byteStream([
        [1, 2],
        [3],
      ]);
      final received = <int>[];
      final tracked = trackFileStream(source, cancelToken: CancelToken());
      await for (final chunk in tracked) {
        received.addAll(chunk);
      }
      expect(received, [1, 2, 3]);
    });
  });

  group('openSendSourceStream', () {
    test('reads local file as byte stream', () async {
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
