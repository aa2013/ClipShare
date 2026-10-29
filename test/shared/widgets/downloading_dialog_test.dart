import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:clipshare/shared/utils/dialog.dart';
import 'package:clipshare/shared/widgets/loading/downloading_dialog.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 在请求已开始后控制响应成功或失败，覆盖被其它弹窗遮挡的完成路径。
class _PendingAdapter implements HttpClientAdapter {
  final response = Completer<ResponseBody>();
  final started = Completer<void>();

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) {
    started.complete();
    return response.future;
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  testWidgets('取消已开始的下载不会触发成功或错误回调', (tester) async {
    late BuildContext host;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) {
      host = context;
      return const Scaffold();
    })));
    var finished = 0;
    var errors = 0;
    var cancelled = 0;
    dialogManager.downloading(host,
      url: 'https://example.test/file', filePath: 'unused-cancelled-download',
      content: const Text('download-content'),
      onFinished: (_) => finished++,
      onError: (_, _) => errors++,
      onCancel: () => cancelled++,
    );
    await tester.pumpAndSettle();
    final dynamic state = tester.state(find.byType(DownloadDialog));
    final adapter = (await tester.runAsync(() async => _PendingAdapter()))!;
    (state.dio as Dio).httpClientAdapter = adapter;
    await tester.runAsync(() async {
      await tester.tap(find.byType(TextButton).last);
      await adapter.started.future;
    });
    await tester.pump();
    await tester.tap(find.byType(TextButton).first);
    adapter.response.complete(ResponseBody.fromString('cancelled', 500));
    await tester.pumpAndSettle();
    expect(cancelled, 1);
    expect(finished, 0);
    expect(errors, 0);
    expect(find.byType(DownloadDialog), findsNothing);
  });

  for (final fail in [false, true]) {
    testWidgets('下载${fail ? '失败' : '成功'}不关闭覆盖窗口', (tester) async {
      final dir = await tester.runAsync(() => Directory.systemTemp.createTemp('update-dialog-test'));
      late BuildContext host;
      await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) {
        host = context;
        return const Scaffold();
      })));
      var completed = 0;
      var errors = 0;
      dialogManager.downloading(host,
        url: 'https://example.test/file', filePath: '${dir!.path}/download',
        content: const Text('download-content'),
        onFinished: (success) => completed++,
        onError: (error, stack) => errors++,
      );
      await tester.pumpAndSettle();
      final dynamic state = tester.state(find.byType(DownloadDialog));
      final adapter = (await tester.runAsync(() async => _PendingAdapter()))!;
      (state.dio as Dio).httpClientAdapter = adapter;
      await tester.runAsync(() async {
        await tester.tap(find.byType(TextButton).last);
        await adapter.started.future;
      });
      await tester.pump();
      final other = dialogManager.open(host, const AlertDialog(content: Text('other')));
      await tester.pump();
      await tester.runAsync(() async {
        if (fail) {
          adapter.response.complete(ResponseBody.fromString('download failed', 500));
        } else {
          adapter.response.complete(ResponseBody.fromString('ok', 200));
        }
        // Dio 写入文件使用真实 IO，等待完成通知而非依赖虚拟时钟。
        for (var i = 0; i < 100 && completed + errors == 0; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
      });
      await tester.pumpAndSettle();
      expect(completed, fail ? 0 : 1);
      expect(errors, fail ? 1 : 0);
      expect(other.closed, isFalse);
      expect(find.text('other'), findsOneWidget);
      expect(find.byType(DownloadDialog), findsNothing);
      await other.close();
      await tester.pumpAndSettle();
      await tester.runAsync(() => dir.delete(recursive: true));
    });
  }
}
