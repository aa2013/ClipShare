import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:clipshare/core/services/device/local_device_info.dart';
import 'package:clipshare/core/services/transport/client/storage/storage_client.dart';
import 'package:clipshare/core/services/transport/file/enums/file_transfer_direction.dart';
import 'package:clipshare/core/services/transport/file/models/file_transfer_task.dart';
import 'package:clipshare/core/services/transport/file/sender/file_send_channel.dart';
import 'package:clipshare/core/services/transport/file/sender/storage_send_channel.dart';
import 'package:clipshare/core/services/transport/storage/storage_ws_service.dart';
import 'package:clipshare/shared/extensions/platform_extension.dart';
import 'package:clipshare/shared/utils/parallerl_task.dart';
import 'package:flutter_test/flutter_test.dart';

/// 假存储客户端：只实现发送通道用到的方法，其余调用一律视为未实现
class _FakeStorageClient implements StorageClient {
  _FakeStorageClient({required this.onUpload});

  final Future<bool> Function(StorageProgressFunc? onProgress) onUpload;

  int createFileCalls = 0;

  @override
  Future<bool> createDirectory(String path) async => true;

  @override
  Future<bool> createFile(
    String path,
    Uint8List bytes, {
    StorageProgressFunc? onProgress,
    bool createDir = false,
  }) async {
    createFileCalls++;
    return true;
  }

  @override
  Future<bool> uploadFile(
    String path,
    String localFilePath, {
    StorageProgressFunc? onProgress,
    CancelToken? cancelToken,
  }) {
    return onUpload(onProgress);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError('${invocation.memberName} is not faked');
  }
}

StorageSendChannel _createChannel(StorageClient client) {
  final wsService = StorageWsService(
    connectUriBuilder: () => Uri.parse('ws://127.0.0.1:1/connect'),
    shouldKeepConnected: () => false,
  );
  addTearDown(wsService.dispose);
  return StorageSendChannel(
    client: client,
    wsService: wsService,
    selfDevId: 'self',
    cachePath: Directory.systemTemp.path,
    buildDatePath: (devId, date) => 'history/$devId/$date',
  );
}

FileSendJob _createJob(CancelToken cancelToken) {
  return FileSendJob(
    device: BaseDeviceInfo(guid: 'dev-1', name: 'dev-1', type: PlatformType('Windows')),
    task: FileTransferTask(
      id: 'task-1',
      direction: FileTransferDirection.send,
      devId: 'dev-1',
      devName: 'dev-1',
      fileName: 'a.bin',
      localPath: '/tmp/a.bin',
      totalSize: 100,
      fileId: 1,
      groupKey: null,
    ),
    cancelToken: cancelToken,
    onProgress: (_) {},
  );
}

void main() {
  test('stops waiting for the upload right after cancel', () async {
    final uploadStarted = Completer<void>();
    final client = _FakeStorageClient(
      onUpload: (onProgress) {
        if (!uploadStarted.isCompleted) {
          uploadStarted.complete();
        }
        // 模拟无法中断的后台上传：永不返回
        return Completer<bool>().future;
      },
    );
    final tokenSource = CancelTokenSource();
    final channel = _createChannel(client);
    final expectation = expectLater(
      channel.send(_createJob(tokenSource.token)),
      throwsA(isA<FileTransferCanceledException>()),
    );
    await uploadStarted.future;

    tokenSource.cancel();

    // 取消后不得继续等待上传收尾
    await expectation.timeout(const Duration(seconds: 2));
  });

  test('reports upload failure when the client returns false', () async {
    final client = _FakeStorageClient(onUpload: (onProgress) async => false);
    final channel = _createChannel(client);

    await expectLater(
      channel.send(_createJob(CancelToken())),
      throwsA(predicate((Object error) => error is Exception && error is! FileTransferCanceledException)),
    );
  });

  test('completes when the upload succeeds', () async {
    final client = _FakeStorageClient(
      onUpload: (onProgress) async {
        onProgress?.call(100, 100);
        return true;
      },
    );
    final channel = _createChannel(client);

    await expectLater(channel.send(_createJob(CancelToken())), completes);
    expect(client.createFileCalls, 1);
  });
}
