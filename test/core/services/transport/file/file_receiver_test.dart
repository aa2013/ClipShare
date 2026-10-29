import 'dart:io';

import 'package:clipshare/core/database/app_database.dart';
import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/database/tables/device.dart';
import 'package:clipshare/core/services/device/device_provider.dart';
import 'package:clipshare/core/services/device/device_registry.dart';
import 'package:clipshare/core/services/history/history_event.dart';
import 'package:clipshare/core/services/history/history_recorder_provider.dart';
import 'package:clipshare/core/services/transport/file/enums/file_transfer_state.dart';
import 'package:clipshare/core/services/transport/file/file_transfer_provider.dart';
import 'package:clipshare/core/services/transport/file/receiver/file_receiver_provider.dart';
import 'package:clipshare/core/settings/app_paths/app_paths.dart';
import 'package:clipshare/core/settings/app_paths/app_paths_provider.dart';
import 'package:clipshare/core/settings/notification/notification_settings.dart';
import 'package:clipshare/core/settings/notification/notification_settings_provider.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// 提供空设备表，接收任务使用未知设备名称。
class _TestDeviceNotifier extends DeviceNotifier {
  @override
  Future<DeviceState> build() async => DeviceState(
        storedDevices: const {},
        discoveryDevices: const {},
        registry: DeviceRegistry(),
        self: unknownDevice(),
        selfId: 'self',
      );
}

/// 收集接收成功事件，隔离历史事件的后续同步处理。
class _TestHistoryRecorder extends HistoryRecorderNotifier {
  final received = <HistoryDeltaEvent>[];

  @override
  Future<void> build() async {}

  /// 记录 [event]，用于验证失败传输不会广播成功历史。
  @override
  void emitDelta(HistoryDeltaEvent event) {
    received.add(event);
  }
}

/// 使用真实本地 socket 验证提前断流与完整接收的落盘、任务及历史结果。
void main() {
  const fileName = 'received.bin';
  const fileId = 123;
  const payload = [1, 2, 3, 4];
  const stateSyncWait = Duration(milliseconds: 250);
  late Directory tempDir;
  late AppDatabase db;
  late ProviderContainer container;
  late _TestHistoryRecorder recorder;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('clipshare-receiver-');
    db = AppDatabase(NativeDatabase.memory());
    recorder = _TestHistoryRecorder();
    container = ProviderContainer(overrides: [
      appDbProvider.overrideWith((ref) async => db),
      deviceProvider.overrideWith(_TestDeviceNotifier.new),
      historyRecorderProvider.overrideWith(() => recorder),
      notificationSettingsProvider.overrideWith((ref) async => const NotificationSettings()),
      appPathsProvider.overrideWith((ref) async => AppPaths(
            rootStorePath: tempDir.path,
            imageStorePath: tempDir.path,
            databasePath: tempDir.path,
            androidPrivateDocumentPath: tempDir.path,
            androidPrivatePicturesPath: tempDir.path,
            documentsPath: tempDir.path,
            luaLibDirPath: tempDir.path,
            cachePath: tempDir.path,
            logsDirPath: tempDir.path,
            updateDownloadFileDirPath: tempDir.path,
          )),
    ]);
    await container.read(appDbProvider.future);
    await container.read(deviceProvider.future);
    await container.read(notificationSettingsProvider.future);
    await container.read(historyRecorderProvider.future);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
    await tempDir.delete(recursive: true);
  });

  for (final scenario in [
    (name: '发送端中途关闭连接', bytes: payload, size: payload.length + 1, success: false),
    (name: '发送端未发送数据即关闭连接', bytes: <int>[], size: payload.length, success: false),
    (name: '实际数据超过声明大小', bytes: payload, size: payload.length - 1, success: false),
    (name: '完整文件', bytes: payload, size: payload.length, success: true),
    (name: '空文件', bytes: <int>[], size: 0, success: true),
  ]) {
    test(scenario.name, () async {
      final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      Socket? sender;
      final subscription = server.listen((socket) async {
        sender = socket;
        socket.add(scenario.bytes);
        await socket.flush();
        await socket.close();
      });
      addTearDown(() async {
        sender?.destroy();
        await subscription.cancel();
        await server.close();
      });

      final receiver = container.read(fileReceiverProvider.notifier);
      await receiver.receiveDirect(
        ip: InternetAddress.loopbackIPv4.address,
        port: server.port,
        size: scenario.size,
        fileName: fileName,
        devId: 'sender',
        fileId: fileId,
      );
      await Future<void>.delayed(stateSyncWait);

      final tasks = container.read(fileTransferProvider);
      final file = File('${tempDir.path}/files/$fileName');
      final histories = await db.select(db.histories).get();
      if (scenario.success) {
        expect(tasks, isEmpty);
        expect(await file.readAsBytes(), scenario.bytes);
        expect(histories, hasLength(1));
        expect(recorder.received, hasLength(1));
      } else {
        expect(tasks.single.state, FileTransferState.error);
        expect(tasks.single.transferredBytes, scenario.bytes.length);
        expect(await file.exists(), isFalse);
        expect(histories, isEmpty);
        expect(recorder.received, isEmpty);
      }
    });
  }
}
