import 'dart:io';
import 'dart:typed_data';

import 'package:clipshare/core/services/transport/client/storage/web_dav_client.dart';
import 'package:clipshare/shared/models/storage/web_dav_config.dart';
import 'package:clipshare/shared/utils/parallerl_task.dart';
import 'package:flutter_test/flutter_test.dart';

const _fileSize = 4 * 1024 * 1024;
const _chunkSize = 64 * 1024;
const _remotePath = '/history/self/2026-01-01/files/big.bin';

/// 本地假 WebDAV：PROPFIND 返回文件元信息，GET 以慢速逐块推送响应体。
class _SlowDavServer {
  _SlowDavServer(this._server) {
    _server.listen(_handle);
  }

  final HttpServer _server;
  int sentBytes = 0;

  String get baseUrl => 'http://127.0.0.1:${_server.port}';

  Future<void> _handle(HttpRequest request) async {
    try {
      switch (request.method) {
        case 'PROPFIND':
          await request.drain<void>();
          request.response
            ..statusCode = 207
            ..headers.contentType = ContentType('application', 'xml', charset: 'utf-8')
            ..write(_propfindBody());
          await request.response.close();
        case 'GET':
          final response = request.response;
          response.contentLength = _fileSize;
          final chunk = Uint8List(_chunkSize);
          while (sentBytes < _fileSize) {
            final remaining = _fileSize - sentBytes;
            final length = remaining < _chunkSize ? remaining : _chunkSize;
            response.add(length == _chunkSize ? chunk : Uint8List.sublistView(chunk, 0, length));
            await response.flush();
            sentBytes += length;
            await Future<void>.delayed(const Duration(milliseconds: 50));
          }
          await response.close();
        default:
          request.response.statusCode = HttpStatus.ok;
          await request.response.close();
      }
    } catch (_) {
      // 客户端中断连接后继续写入会抛错，忽略即可
    }
  }

  String _propfindBody() {
    return '''<?xml version="1.0" encoding="utf-8"?>
<D:multistatus xmlns:D="DAV:">
  <D:response>
    <D:href>$_remotePath</D:href>
    <D:propstat>
      <D:prop>
        <D:getcontentlength>$_fileSize</D:getcontentlength>
        <D:getcontenttype>application/octet-stream</D:getcontenttype>
        <D:resourcetype/>
      </D:prop>
      <D:status>HTTP/1.1 200 OK</D:status>
    </D:propstat>
  </D:response>
</D:multistatus>''';
  }

  Future<void> close() => _server.close(force: true);
}

void main() {
  test('aborts the download shortly after cancel', () async {
    final server = _SlowDavServer(await HttpServer.bind(InternetAddress.loopbackIPv4, 0));
    addTearDown(server.close);

    final config = WebDAVConfig(
      server: server.baseUrl,
      username: 'user',
      password: 'pass',
      baseDir: '/',
      displayName: 'test',
    );
    final client = WebDAVClient(config);
    final tempDir = await Directory.systemTemp.createTemp('clipshare_webdav_download_cancel');
    addTearDown(() => tempDir.delete(recursive: true));
    final localPath = '${tempDir.path}/big.bin';

    final tokenSource = CancelTokenSource();
    final download = client.downloadFile(
      'history/self/2026-01-01/files/big.bin',
      localPath,
      cancelToken: tokenSource.token,
    );
    // 等待下载进入传输阶段
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final canceledAt = DateTime.now();
    tokenSource.cancel();
    final downloaded = await download.timeout(const Duration(seconds: 10));
    final elapsedMs = DateTime.now().difference(canceledAt).inMilliseconds;

    expect(downloaded, isFalse);
    expect(elapsedMs, lessThan(1500));
    // 真实中断：本地只写入部分内容，且句柄已释放（否则删除临时目录会失败）
    final file = File(localPath);
    expect(await file.exists(), isTrue);
    expect(await file.length(), lessThan(_fileSize));
  }, timeout: const Timeout(Duration(seconds: 40)));
}
