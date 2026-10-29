import 'dart:io';

import 'package:clipshare/core/services/transport/client/storage/web_dav_client.dart';
import 'package:clipshare/shared/models/storage/web_dav_config.dart';
import 'package:clipshare/shared/utils/parallerl_task.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('aborts the upload shortly after cancel', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    var receivedBytes = 0;
    server.listen((request) async {
      try {
        if (request.method == 'PUT') {
          // 模拟慢速服务端：逐块读取并延迟，客户端若真的中断连接就不会读满整个文件
          await for (final chunk in request) {
            receivedBytes += chunk.length;
            await Future<void>.delayed(const Duration(milliseconds: 50));
          }
          request.response.statusCode = HttpStatus.created;
        } else {
          request.response.statusCode = HttpStatus.ok;
        }
      } catch (_) {
        // 客户端中断连接后继续读取会抛错，忽略即可
      } finally {
        try {
          await request.response.close();
        } catch (_) {
          // 连接已断开
        }
      }
    });
    addTearDown(() => server.close(force: true));

    final config = WebDAVConfig(
      server: 'http://127.0.0.1:${server.port}',
      username: 'user',
      password: 'pass',
      baseDir: '/',
      displayName: 'test',
    );
    final client = WebDAVClient(config);
    final tempDir = await Directory.systemTemp.createTemp('clipshare_webdav_cancel');
    addTearDown(() => tempDir.delete(recursive: true));
    const fileSize = 8 * 1024 * 1024;
    final file = File('${tempDir.path}/big.bin');
    await file.writeAsBytes(List<int>.filled(fileSize, 7), flush: true);

    final tokenSource = CancelTokenSource();
    final upload = client.uploadFile(
      'history/self/2026-01-01/files/big.bin',
      file.path,
      cancelToken: tokenSource.token,
    );
    // 等待上传进入传输阶段
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final canceledAt = DateTime.now();
    tokenSource.cancel();
    final uploaded = await upload.timeout(const Duration(seconds: 10));
    final elapsedMs = DateTime.now().difference(canceledAt).inMilliseconds;

    expect(uploaded, isFalse);
    expect(elapsedMs, lessThan(1500));
    // 真实中断：服务端不应收到完整文件
    expect(receivedBytes, lessThan(fileSize));
  }, timeout: const Timeout(Duration(seconds: 40)));
}
