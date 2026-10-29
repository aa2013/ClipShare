import 'dart:convert';
import 'dart:io';

import 'package:clipshare/core/services/transport/client/storage/web_dav_client.dart';
import 'package:clipshare/shared/models/storage/web_dav_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WebDAV uploadFile createDir fallback', () {
    late _TestWebDavServer webDavServer;
    late WebDAVClient client;

    setUp(() async {
      webDavServer = _TestWebDavServer();
      await webDavServer.start();
      await webDavServer.createDirectory('/clipshare');
      client = WebDAVClient(
        WebDAVConfig(
          server: webDavServer.uri.toString(),
          username: 'tester',
          password: 'secret',
          baseDir: '/clipshare',
          displayName: 'test-webdav-upload-fallback',
        ),
      );
    });

    tearDown(() async {
      await webDavServer.dispose();
    });

    test('failed direct file upload cascades directories before retrying', () async {
      const path = '/upload/fallback/files/file.txt';
      webDavServer.failPutOnce('/clipshare$path');
      final tempDir = await Directory.systemTemp.createTemp('clipshare_upload_');
      addTearDown(() => tempDir.delete(recursive: true));
      final localFile = File('${tempDir.path}/source.txt');
      await localFile.writeAsString('upload');

      expect(
        await client.uploadFile(path, localFile.path, createDir: true),
        isTrue,
      );

      expect(webDavServer.requests, <String>[
        'PUT /clipshare/upload/fallback/files/file.txt',
        'MKCOL /clipshare/upload/fallback/files',
        'PROPFIND /clipshare/upload/fallback/files',
        'MKCOL /clipshare/upload',
        'MKCOL /clipshare/upload/fallback',
        'MKCOL /clipshare/upload/fallback/files',
        'PUT /clipshare/upload/fallback/files/file.txt',
      ]);
    });

    test('uploadFile without createDir keeps direct upload failure', () async {
      const path = '/upload/no-fallback/file.txt';
      webDavServer.failPutOnce('/clipshare$path');
      final tempDir = await Directory.systemTemp.createTemp('clipshare_upload_');
      addTearDown(() => tempDir.delete(recursive: true));
      final localFile = File('${tempDir.path}/source.txt');
      await localFile.writeAsString('upload');

      expect(await client.uploadFile(path, localFile.path), isFalse);

      expect(webDavServer.requests, <String>[
        'PUT /clipshare/upload/no-fallback/file.txt',
      ]);
    });
  });
}

class _StoredEntry {
  final bool isDirectory;
  List<int> bytes;

  _StoredEntry.directory() : isDirectory = true, bytes = const <int>[];

  _StoredEntry.file(this.bytes) : isDirectory = false;
}

/// 最小 WebDAV 测试服务端，只覆盖当前存储补拉回归场景需要的协议子集。
class _TestWebDavServer {
  late final HttpServer _server;
  final Map<String, _StoredEntry> _entries = <String, _StoredEntry>{
    '/': _StoredEntry.directory(),
  };
  final List<String> requests = <String>[];
  final Set<String> _mkColFailPaths = <String>{};
  final Set<String> _mkColFailOncePaths = <String>{};
  final Set<String> _putFailPaths = <String>{};
  final Set<String> _putFailOncePaths = <String>{};

  Uri get uri => Uri.parse('http://127.0.0.1:${_server.port}');

  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server.listen(_handleRequest);
  }

  Future<void> dispose() async {
    await _server.close(force: true);
  }

  Future<void> writeJson(String path, Map<String, dynamic> json) {
    return writeBytes(path, utf8.encode(jsonEncode(json)));
  }

  /// 允许测试显式创建空目录，覆盖只列目录不写文件的场景。
  Future<void> createDirectory(String path) async {
    final normalizedPath = _normalize(path);
    _ensureParentDirectories(normalizedPath);
    _entries.putIfAbsent(normalizedPath, _StoredEntry.directory);
  }

  /// 为指定目录制造 MKCOL 失败，便于稳定复现初始化阶段错误。
  void failMkCol(String path) {
    _mkColFailPaths.add(_normalize(path));
  }

  /// 让指定路径的下一次 MKCOL 请求失败，便于验证直建失败后的级联回退。
  void failMkColOnce(String path) {
    _mkColFailOncePaths.add(_normalize(path));
  }

  /// 让指定路径的所有 PUT 请求失败，便于验证最终重试失败的返回结果。
  void failPut(String path) {
    _putFailPaths.add(_normalize(path));
  }

  /// 让指定路径的下一次 PUT 请求失败，便于验证文件直写回退流程。
  void failPutOnce(String path) {
    _putFailOncePaths.add(_normalize(path));
  }

  Future<void> writeBytes(String path, List<int> bytes) async {
    final normalizedPath = _normalize(path);
    _ensureParentDirectories(normalizedPath);
    _entries[normalizedPath] = _StoredEntry.file(List<int>.from(bytes));
  }

  Future<void> _handleRequest(HttpRequest request) async {
    final path = _normalize(request.uri.path);
    requests.add('${request.method} $path');
    switch (request.method) {
      case 'GET':
        await _handleGet(request, path);
        return;
      case 'PUT':
        await _handlePut(request, path);
        return;
      case 'DELETE':
        await _handleDelete(request, path);
        return;
      case 'MKCOL':
        await _handleMkCol(request, path);
        return;
      case 'PROPFIND':
        await _handlePropfind(request, path);
        return;
      default:
        request.response.statusCode = HttpStatus.methodNotAllowed;
        await request.response.close();
    }
  }

  Future<void> _handleGet(HttpRequest request, String path) async {
    final entry = _entries[path];
    if (entry == null || entry.isDirectory) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }
    request.response.statusCode = HttpStatus.ok;
    request.response.add(entry.bytes);
    await request.response.close();
  }

  Future<void> _handlePut(HttpRequest request, String path) async {
    final bytes = await request.fold<List<int>>(
      <int>[],
      (prev, element) => prev..addAll(element),
    );
    if (_putFailPaths.contains(path) || _putFailOncePaths.remove(path)) {
      request.response.statusCode = HttpStatus.conflict;
      await request.response.close();
      return;
    }
    _ensureParentDirectories(path);
    _entries[path] = _StoredEntry.file(bytes);
    request.response.statusCode = HttpStatus.created;
    await request.response.close();
  }

  Future<void> _handleDelete(HttpRequest request, String path) async {
    if (!_entries.containsKey(path)) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }
    _entries.removeWhere(
      (entryPath, _) => entryPath == path || entryPath.startsWith('$path/'),
    );
    request.response.statusCode = HttpStatus.noContent;
    await request.response.close();
  }

  Future<void> _handleMkCol(HttpRequest request, String path) async {
    if (_mkColFailPaths.contains(path) || _mkColFailOncePaths.remove(path)) {
      request.response.statusCode = HttpStatus.internalServerError;
      await request.response.close();
      return;
    }
    final parentPath = path.substring(0, path.lastIndexOf('/'));
    final parent = parentPath.isEmpty ? '/' : parentPath;
    final parentEntry = _entries[parent];
    if (parentEntry == null || !parentEntry.isDirectory) {
      request.response.statusCode = HttpStatus.conflict;
      await request.response.close();
      return;
    }
    if (_entries.containsKey(path)) {
      request.response.statusCode = HttpStatus.methodNotAllowed;
      await request.response.close();
      return;
    }
    _entries[path] = _StoredEntry.directory();
    request.response.statusCode = HttpStatus.created;
    await request.response.close();
  }

  Future<void> _handlePropfind(HttpRequest request, String path) async {
    final entry = _entries[path];
    if (entry == null) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }
    final depth = request.headers.value('Depth') ?? '0';
    final responses = <String>[
      _buildPropfindResponse(path, entry),
    ];
    if (depth != '0' && entry.isDirectory) {
      final children =
          _entries.entries
              .where((item) => _isDirectChild(path, item.key))
              .toList()
            ..sort((a, b) => a.key.compareTo(b.key));
      for (final child in children) {
        responses.add(_buildPropfindResponse(child.key, child.value));
      }
    }
    request.response.statusCode = HttpStatus.multiStatus;
    request.response.headers.contentType = ContentType(
      'text',
      'xml',
      charset: 'utf-8',
    );
    request.response.write(
      '<?xml version="1.0" encoding="utf-8"?>'
      '<d:multistatus xmlns:d="DAV:">${responses.join()}</d:multistatus>',
    );
    await request.response.close();
  }

  String _buildPropfindResponse(String path, _StoredEntry entry) {
    final href = entry.isDirectory && path != '/' ? '$path/' : path;
    final displayName =
        href.split('/').where((item) => item.isNotEmpty).lastOrNull ?? '';
    final contentType = entry.isDirectory
        ? 'httpd/unix-directory'
        : 'application/octet-stream';
    final contentLength = entry.isDirectory
        ? '0'
        : entry.bytes.length.toString();
    return '<d:response>'
        '<d:href>$href</d:href>'
        '<d:propstat>'
        '<d:prop>'
        '<d:displayname>$displayName</d:displayname>'
        '<d:getcontentlength>$contentLength</d:getcontentlength>'
        '<d:getcontenttype>$contentType</d:getcontenttype>'
        '<d:getlastmodified>Mon, 29 Jun 2026 00:00:00 GMT</d:getlastmodified>'
        '<d:resourcetype>${entry.isDirectory ? '<d:collection/>' : ''}</d:resourcetype>'
        '</d:prop>'
        '<d:status>HTTP/1.1 200 OK</d:status>'
        '</d:propstat>'
        '</d:response>';
  }

  String _normalize(String path) {
    final unixPath = path.replaceAll('\\', '/');
    if (unixPath.isEmpty || unixPath == '/') {
      return '/';
    }
    final normalized = unixPath
        .replaceAll(RegExp(r'^/+'), '')
        .replaceAll(RegExp(r'/+'), '/')
        .replaceAll(RegExp(r'/+$'), '');
    return normalized.isEmpty ? '/' : '/$normalized';
  }

  void _ensureParentDirectories(String path) {
    final parts = path.split('/')..removeWhere((item) => item.isEmpty);
    var current = '';
    for (var i = 0; i < parts.length - 1; i++) {
      current += '/${parts[i]}';
      _entries.putIfAbsent(current, _StoredEntry.directory);
    }
  }

  bool _isDirectChild(String parent, String child) {
    if (parent == '/') {
      return child != '/' && child.substring(1).split('/').length == 1;
    }
    if (!child.startsWith('$parent/')) {
      return false;
    }
    return child.substring(parent.length + 1).split('/').length == 1;
  }
}

extension on Iterable<String> {
  String? get lastOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) {
      return null;
    }
    var current = iterator.current;
    while (iterator.moveNext()) {
      current = iterator.current;
    }
    return current;
  }
}
