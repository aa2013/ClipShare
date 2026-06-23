import 'dart:typed_data';

import 'package:clipshare/app/data/models/exception_info.dart';
import 'package:clipshare/app/data/models/storage/storage_item.dart';
import 'package:clipshare/app/handlers/storage/storage_client.dart';
import 'package:clipshare/app/modules/settings_module/pages/settings_section_view_base.dart';
import 'package:flutter_test/flutter_test.dart';

/// 简单的测试替身，用于验证 [StorageClient] 抽象基类的共享逻辑。
class _FakeStorageClient extends StorageClient {
  final List<String> createdPaths = <String>[];
  final Set<String> failedPaths = <String>{};
  final Set<String> existingDirectories = <String>{};

  String formatErrorDetailsForTest(String op, Map<String, Object?> details) {
    return formatStorageErrorDetails(op, details);
  }

  @override
  Future<bool> createDirectory(String path) async {
    createdPaths.add(path);
    if (failedPaths.contains(path)) {
      return false;
    }
    existingDirectories.add(path);
    return true;
  }

  @override
  Future<bool> createFile(
    String path,
    Uint8List bytes, {
    StorageProgressFunc? onProgress,
    bool createDir = false,
  }) async {
    return true;
  }

  @override
  Future<bool> deleteDirectory(String path) async {
    return true;
  }

  @override
  Future<bool> deleteFile(String path) async {
    return true;
  }

  @override
  Future<bool> downloadFile(
    String path,
    String localPath, {
    StorageProgressFunc? onProgress,
    bool isLocalDir = false,
  }) async {
    return true;
  }

  @override
  Future<bool> isDirectory(String path) async {
    return existingDirectories.contains(path);
  }

  @override
  Future<bool> isFile(String path) async {
    return true;
  }

  @override
  Future<List<StorageItem>> list({String path = "", bool recursive = false}) async {
    return const <StorageItem>[];
  }

  @override
  Future<List<String>> listRootDirectoryNames() async {
    return const <String>[];
  }

  @override
  Future<List<int>?> readFileBytes(
    String path, {
    StorageProgressFunc? onProgress,
  }) async {
    return const <int>[];
  }

  @override
  Future<ExceptionInfo?> testConnect() async {
    return null;
  }

  @override
  Future<bool> uploadFile(
    String path,
    String localFilePath, {
    StorageProgressFunc? onProgress,
  }) async {
    return true;
  }
}

void main() {
  group('StorageClient', () {

    test('createDirectory uses direct creation with normalized path by default', () async {
      final client = _FakeStorageClient();

      final created = await client.createDirectory(' //foo///bar// ');

      expect(created, isTrue);
      expect(client.createdPaths, <String>['/foo/bar']);
    });

    test('createDirectory creates each level when stepwise mode is enabled', () async {
      final client = _FakeStorageClient();

      final created = await client.createDirectory('/foo//bar/baz/');

      expect(created, isTrue);
      expect(client.createdPaths, <String>['/foo', '/foo/bar', '/foo/bar/baz']);
    });

    test('createDirectory stops when a stepwise segment fails', () async {
      final client = _FakeStorageClient();
      client.failedPaths.add('/foo/bar');

      final created = await client.createDirectory('/foo/bar/baz');

      expect(created, isFalse);
      expect(client.createdPaths, <String>['/foo', '/foo/bar']);
    });

    test('formatStorageErrorDetails includes op and skips null values', () {
      final client = _FakeStorageClient();

      final details = client.formatErrorDetailsForTest('createFile', <String, Object?>{
        'path': '/foo/bar.txt',
        'bytesLength': 12,
        'localPath': null,
        'createDir': true,
      });

      expect(details, contains('op=createFile'));
      expect(details, contains('path=/foo/bar.txt'));
      expect(details, contains('bytesLength=12'));
      expect(details, contains('createDir=true'));
      expect(details, isNot(contains('localPath=')));
    });
  });
}
