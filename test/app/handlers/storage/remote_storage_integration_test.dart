import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:clipshare/app/data/models/storage/storage_item.dart';
import 'package:clipshare/app/handlers/storage/storage_client.dart';
import 'package:clipshare/app/handlers/storage/web_dav_client.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'remote_storage_integration_test_config.dart';
import 'remote_storage_integration_test_target.dart';

void main() {
  final hasLocalConfig = RemoteStorageIntegrationTestConfigLoader.hasLocalConfig();
  final targets = hasLocalConfig
      ? RemoteStorageIntegrationTestConfigLoader.loadTargets()
      : const <RemoteStorageIntegrationTarget>[];
  final skipReason = hasLocalConfig
      ? null
      : 'Missing local remote storage config at '
            '${RemoteStorageIntegrationTestConfigLoader.localConfigPath}. '
            'Copy ${RemoteStorageIntegrationTestConfigLoader.exampleConfigPath} and '
            'fill in your private credentials.';

  setUpAll(() {
    Get.testMode = true;
    Get.put(ConfigService());
  });

  tearDownAll(() {
    Get.reset();
  });

  if (!hasLocalConfig) {
    test(
      'requires a local remote storage integration config file',
      () {},
      skip: skipReason,
    );
    return;
  }

  for (final target in targets) {
    group('Remote storage integration ${target.kind.name} ${target.displayName}', () {
      late StorageClient client;
      late Directory localTempDir;

      setUpAll(() async {
        client = target.toClient();
        localTempDir = await Directory.systemTemp.createTemp('codex-storage-${target.slug}-');
        final connectResult = await client.testConnect();
        expect(connectResult, isNull);
      });

      tearDownAll(() async {
        if (await localTempDir.exists()) {
          await localTempDir.delete(recursive: true);
        }
      });

      test('testConnect succeeds against the provided endpoint', () async {
        final connectResult = await client.testConnect();

        expect(connectResult, isNull);
      });

      test('testConnect ignores a missing baseDir and only validates auth and connectivity', () async {
        final missingBaseDirClient = target.buildClient(
          baseDir: '/codex-missing-${DateTime.now().millisecondsSinceEpoch}',
          displayName: 'codex-storage-missing-dir-${target.slug}',
        );

        final connectResult = await missingBaseDirClient.testConnect();

        expect(connectResult, isNull);
      });

      test('root path is accepted by the public client contract', () async {
        final rootItems = await client.list(path: '/');

        expect(rootItems, isA<List<StorageItem>>());
        if(client is WebDAVClient) {
          expect(await client.isFile('/'), isFalse);
        }
      });

      test('listRootDirectoryNames returns directory names in the public client contract', () async {
        final rootDirectories = await client.listRootDirectoryNames();

        expect(rootDirectories, isA<List<String>>());
        expect(rootDirectories.every((item) => item.trim().isNotEmpty), isTrue);
        expect(rootDirectories.any((item) => item.contains('://')), isFalse);
        expect(rootDirectories.any((item) => item.startsWith('/remote.php')), isFalse);
      });

      test('list returns storage items in the public client contract', () async {
        final items = await client.list(path: '/');

        expect(items, isA<List<StorageItem>>());
        expect(items.any((item) => item.path.trim().isEmpty), isFalse);
        expect(items.any((item) => item.path.contains('://')), isFalse);
        expect(items.any((item) => item.path.startsWith('/remote.php')), isFalse);
      });

      test('createDirectory builds nested directories stepwise', () async {
        final isWebDAV = client is WebDAVClient;
        if(!isWebDAV){
          return true;
        }
        final remoteRoot = _newRemoteRoot(target, 'dirs');
        final nestedDirectory = '$remoteRoot/level-1/level-2/level-3';

        try {
          expect(await client.createDirectory(nestedDirectory), isTrue);
          expect(await client.isDirectory(remoteRoot), isTrue);
          expect(await client.isDirectory('$remoteRoot/level-1'), isTrue);
          expect(await client.isDirectory('$remoteRoot/level-1/level-2'), isTrue);
          expect(await client.isDirectory(nestedDirectory), isTrue);

          final items = await client.list(path: remoteRoot, recursive: true);
          final flattenedPaths = _flattenItems(items).map((item) => item.path).toList();

          expect(_containsStoragePath(flattenedPaths, '$remoteRoot/level-1', isDirectory: true), isTrue);
          expect(_containsStoragePath(flattenedPaths, '$remoteRoot/level-1/level-2', isDirectory: true), isTrue);
          expect(_containsStoragePath(flattenedPaths, nestedDirectory, isDirectory: true), isTrue);
        } finally {
          await _cleanupRemoteTree(client, remoteRoot);
        }
      });

      test('createDirectory on existing directory is treated as success', () async {
        final isWebDAV = client is WebDAVClient;
        if(!isWebDAV){
          return true;
        }
        final remoteRoot = _newRemoteRoot(target, 'existing-dir');

        try {
          expect(await client.createDirectory(remoteRoot), isTrue);
          expect(await client.createDirectory(remoteRoot), isTrue);
          expect(await client.isDirectory(remoteRoot), isTrue);
        } finally {
          await _cleanupRemoteTree(client, remoteRoot);
        }
      });

      test('file lifecycle covers create upload list read download and delete', () async {
        final remoteRoot = _newRemoteRoot(target, 'files');
        final bytesFilePath = '$remoteRoot/from-bytes/hello.txt';
        final uploadFilePath = '$remoteRoot/from-upload/local.txt';
        final bytesDirectoryPath = '$remoteRoot/from-bytes';
        final uploadDirectoryPath = '$remoteRoot/from-upload';
        final bytesData = Uint8List.fromList(utf8.encode('hello-from-bytes-${target.slug}'));
        final uploadData = 'hello-from-upload-${target.slug}';
        final sourceFile = File('${localTempDir.path}/source-${target.slug}.txt');
        final downloadDir = Directory('${localTempDir.path}/download-${target.slug}');
        var createProgress = <int>[];
        var uploadProgress = <int>[];
        var downloadProgress = <int>[];
        var readProgress = <int>[];

        try {
          await sourceFile.writeAsString(uploadData);

          expect(
            await client.createFile(
              bytesFilePath,
              bytesData,
              createDir: true,
              onProgress: (count, total) => createProgress = <int>[count, total],
            ),
            isTrue,
          );
          final isWebDAV = client is WebDAVClient;
          if(isWebDAV){
            expect(await client.isDirectory(bytesDirectoryPath), isTrue);
            expect(createProgress, isNotEmpty);
            expect(createProgress.first, greaterThan(0));
            expect(createProgress.last, greaterThan(0));
            expect(createProgress.first, equals(createProgress.last));
          }
          expect(await client.isFile(bytesFilePath), isTrue);

          expect(await client.createDirectory(uploadDirectoryPath), isTrue);

          expect(
            await client.uploadFile(
              uploadFilePath,
              sourceFile.path,
              onProgress: (count, total) => uploadProgress = <int>[count, total],
            ),
            isTrue,
          );
          expect(uploadProgress, hasLength(2));
          expect(uploadProgress[0], greaterThan(0));
          expect(uploadProgress[1], greaterThan(0));
          expect(uploadProgress[0], equals(uploadProgress[1]));
          expect(await client.isFile(uploadFilePath), isTrue);

          if(isWebDAV) {
            final listedItems = await client.list(path: remoteRoot, recursive: true);
            final listedPaths = _flattenItems(listedItems).map((item) => item.path).toList();
            expect(_containsStoragePath(listedPaths, bytesDirectoryPath, isDirectory: true), isTrue);
            expect(_containsStoragePath(listedPaths, bytesFilePath), isTrue);
            expect(_containsStoragePath(listedPaths, uploadDirectoryPath, isDirectory: true), isTrue);
            expect(_containsStoragePath(listedPaths, uploadFilePath), isTrue);
            expect(listedPaths.any(_hasObviousServerPathLeak), isFalse);
          }

          final readBytes = await client.readFileBytes(
            bytesFilePath,
            onProgress: (count, total) => readProgress = <int>[count, total],
          );
          expect(readBytes, isNotNull);
          expect(utf8.decode(readBytes!), equals(utf8.decode(bytesData)));
          if (readProgress.isNotEmpty) {
            expect(readProgress, hasLength(2));
            expect(readProgress[0], greaterThan(0));
            expect(readProgress[1], greaterThan(0));
            expect(readProgress[0], equals(readProgress[1]));
          }

          expect(
            await client.downloadFile(
              uploadFilePath,
              downloadDir.path,
              isLocalDir: true,
              onProgress: (count, total) => downloadProgress = <int>[count, total],
            ),
            isTrue,
          );
          final downloadedFile = File('${downloadDir.path}/local.txt');
          expect(await downloadedFile.exists(), isTrue);
          expect(await downloadedFile.readAsString(), equals(uploadData));
          if (downloadProgress.isNotEmpty) {
            expect(downloadProgress, hasLength(2));
            expect(downloadProgress[0], greaterThan(0));
            expect(downloadProgress[1], greaterThan(0));
            expect(downloadProgress[0], equals(downloadProgress[1]));
          }

          expect(await client.deleteFile(bytesFilePath), isTrue);
          expect(await client.deleteFile(uploadFilePath), isTrue);
          if(isWebDAV) {
            expect(await client.isFile(bytesFilePath), isFalse);
            expect(await client.isFile(uploadFilePath), isFalse);
            expect(await client.deleteDirectory(remoteRoot), isTrue);
            expect(await client.isDirectory(remoteRoot), isFalse);
          }
        } finally {
          await _cleanupRemoteTree(client, remoteRoot);
          if (await downloadDir.exists()) {
            await downloadDir.delete(recursive: true);
          }
          if (await sourceFile.exists()) {
            await sourceFile.delete();
          }
        }
      });
    });
  }
}

/// 生成每次运行唯一的远端测试根目录，避免和历史数据冲突。
String _newRemoteRoot(RemoteStorageIntegrationTarget target, String purpose) {
  return '/codex-${target.slug}-$purpose-${DateTime.now().microsecondsSinceEpoch}';
}

/// 统一按客户端公开契约归一化路径，避免把具体协议细节写进断言里。
String _normalizePublicPath(String path, {bool isDirectory = false}) {
  var normalizedPath = path.trim().replaceAll(RegExp(r'[/\\]+'), '/');
  normalizedPath = normalizedPath.replaceFirst(RegExp(r'^/+'), '/');
  if (normalizedPath.isEmpty) {
    return isDirectory ? '/' : '';
  }
  if (isDirectory) {
    return normalizedPath.endsWith('/') ? normalizedPath : '$normalizedPath/';
  }
  return normalizedPath.replaceFirst(RegExp(r'/+$'), '');
}

/// 判断实际路径是否满足公开契约下的期望相对路径，允许存在实现内部附带的前缀。
bool _containsStoragePath(
  Iterable<String> actualPaths,
  String expectedPath, {
  bool isDirectory = false,
}) {
  final normalizedExpected = _normalizePublicPath(
    expectedPath,
    isDirectory: isDirectory,
  );
  final expectedSuffix = normalizedExpected.startsWith('/')
      ? normalizedExpected.substring(1)
      : normalizedExpected;
  return actualPaths.any((actualPath) {
    final normalizedActual = _normalizePublicPath(
      actualPath,
      isDirectory: isDirectory,
    );
    if (normalizedActual == normalizedExpected) {
      return true;
    }
    if (expectedSuffix.isEmpty) {
      return false;
    }
    return normalizedActual.endsWith('/$expectedSuffix') ||
        normalizedActual.endsWith(expectedSuffix);
  });
}

/// 统一识别明显的服务端实现细节泄露，避免对外契约回退。
bool _hasObviousServerPathLeak(String path) {
  return path.contains('://') || path.startsWith('/remote.php');
}

/// 展平递归列表结果，方便统一断言和清理。
Iterable<StorageItem> _flattenItems(List<StorageItem> items) sync* {
  for (final item in items) {
    yield item;
    if (item.children.isNotEmpty) {
      yield* _flattenItems(item.children);
    }
  }
}

/// 清理远端测试目录，避免集成测试残留脏数据影响后续运行。
Future<void> _cleanupRemoteTree(StorageClient client, String rootPath) async {
  try {
    if(client is WebDAVClient) {
      if (!await client.isDirectory(rootPath)) {
        return;
      }
    }
    final items = await client.list(path: rootPath, recursive: true);
    final flattenedItems = _flattenItems(items).toList();
    final fileItems = flattenedItems.where((item) => !item.isDir);
    final directoryItems = flattenedItems.where((item) => item.isDir).toList().reversed;
    for (final item in fileItems) {
      await client.deleteFile(item.path);
    }
    for (final item in directoryItems) {
      await client.deleteDirectory(item.path);
    }
    await client.deleteDirectory(rootPath);
  } catch (_) {
    // 清理失败不覆盖主断言，避免隐藏真正的业务问题。
  }
}
