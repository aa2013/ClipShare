import 'dart:async';

import 'package:clipshare/core/database/app_database.dart';
import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/database/tables/device.dart';
import 'package:clipshare/core/services/device/device_provider.dart';
import 'package:clipshare/core/services/device/device_registry.dart';
import 'package:clipshare/core/services/device/local_device_info.dart';
import 'package:clipshare/core/services/device/local_device_info_provider.dart';
import 'package:clipshare/core/services/transport/file/enums/file_transfer_direction.dart';
import 'package:clipshare/core/services/transport/file/enums/file_transfer_state.dart';
import 'package:clipshare/core/services/transport/file/file_transfer_provider.dart';
import 'package:clipshare/core/services/transport/file/models/pending_transfer_file.dart';
import 'package:clipshare/core/services/transport/file/sender/direct_socket_send_channel.dart';
import 'package:clipshare/core/services/transport/file/sender/file_send_channel.dart';
import 'package:clipshare/core/services/transport/file/sender/forward_send_channel.dart';
import 'package:clipshare/shared/enums/transport_protocol.dart';
import 'package:clipshare/shared/extensions/platform_extension.dart';
import 'package:clipshare/shared/models/version.dart';
import 'package:clipshare/shared/utils/parallerl_task.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// 可控收口的假直连通道：send 记录入参并挂起，由测试按索引释放
class _FakeDirectChannel extends DirectSocketSendChannel {
  final sent = <FileSendJob>[];
  final _releaseCompleters = <Completer<void>>[];

  @override
  void build() {}

  @override
  Future<void> send(FileSendJob job) async {
    sent.add(job);
    job.onProgress(job.task.totalSize);
    final completer = Completer<void>();
    _releaseCompleters.add(completer);
    await completer.future;
    if (job.cancelToken.isCanceled) {
      throw const FileTransferCanceledException();
    }
  }

  /// 释放第 [index] 个挂起的发送任务
  void releaseAt(int index) {
    _releaseCompleters[index].complete();
  }
}

/// 假中转通道：直连协议设备不应触达，触达即测试失败
class _FakeForwardChannel extends ForwardSendChannel {
  @override
  void build() {}

  @override
  Future<void> send(FileSendJob job) {
    fail('forward channel should not be used for direct devices');
  }
}

class _FakeDeviceNotifier extends DeviceNotifier {
  final DeviceState _state;

  _FakeDeviceNotifier(this._state);

  @override
  Future<DeviceState> build() async => _state;
}

Device _device(String guid) => emptyDevice(
      guid: guid,
      devName: 'name-$guid',
      type: 'Windows',
      isPaired: true,
    );

void main() {
  late AppDatabase db;
  late _FakeDirectChannel directChannel;
  late DeviceRegistry registry;
  late ProviderContainer container;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    directChannel = _FakeDirectChannel();
    registry = DeviceRegistry();
    final container_ = ProviderContainer(
      overrides: [
        appDbProvider.overrideWith((ref) async => db),
        localDeviceInfoProvider.overrideWith(
          (ref) async => LocalDeviceInfo(
            baseDeviceInfo: BaseDeviceInfo(guid: 'self', name: 'self', type: PlatformType('Windows')),
            appVersion: AppVersion('1.0.0', '100'),
            androidOsVersion: 0,
            localName: 'self',
            self: unknownDevice(),
          ),
        ),
        deviceProvider.overrideWith(
          () => _FakeDeviceNotifier(
            DeviceState(
              storedDevices: {
                for (final guid in ['dev-1', 'dev-2']) guid: _device(guid),
              },
              discoveryDevices: {},
              registry: registry,
              self: _device('self'),
              selfId: 'self',
            ),
          ),
        ),
        directSocketSendChannelProvider.overrideWith(() => directChannel),
        forwardSendChannelProvider.overrideWith(_FakeForwardChannel.new),
      ],
    );
    container = container_;
    //预热异步 provider，避免 requireValue 命中加载态
    await container.read(appDbProvider.future);
    await container.read(localDeviceInfoProvider.future);
    await container.read(deviceProvider.future);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  /// 等待异步调度链传播
  Future<void> _settle() async {
    await container.read(deviceProvider.future);
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }

  PendingTransferFile _pending(String name, {List<String> dirs = const []}) {
    return PendingTransferFile(
      filePath: '/tmp/$name',
      fileName: name,
      size: 100,
      relativeDirs: dirs,
    );
  }

  test('入队即创建任务并携带协议文件名与分组键', () async {
    final baseDev = BaseDeviceInfo.fromDevice(_device('dev-1'));
    registry.addDevice(baseDev, TransportProtocol.direct, AppVersion('1.0.0', '100'), AppVersion('1.0.0', '100'));
    await container.read(fileTransferProvider.notifier).sendFiles(baseDev, [
      _pending('a.png', dirs: ['photos']),
      _pending('b.png'),
    ]);
    await _settle();

    final tasks = container.read(fileTransferProvider);
    expect(tasks.length, 2);
    final grouped = tasks.firstWhere((task) => task.fileName == 'photos/a.png');
    expect(grouped.groupKey, 'photos');
    expect(grouped.direction, FileTransferDirection.send);
    expect(grouped.devId, 'dev-1');
    expect(grouped.fileId, isNot(0));
    expect(tasks.any((task) => task.fileName == 'b.png' && task.groupKey == null), isTrue);
  });

  test('同一设备的发送严格串行，完成后自动推进下一个', () async {
    final baseDev = BaseDeviceInfo.fromDevice(_device('dev-1'));
    registry.addDevice(baseDev, TransportProtocol.direct, AppVersion('1.0.0', '100'), AppVersion('1.0.0', '100'));
    await container.read(fileTransferProvider.notifier).sendFiles(baseDev, [
      _pending('a.txt'),
      _pending('b.txt'),
    ]);
    await _settle();

    //第一个任务开始传输，第二个仍在排队
    expect(directChannel.sent.length, 1);
    var tasks = container.read(fileTransferProvider);
    expect(tasks.firstWhere((task) => task.fileName == 'a.txt').state, FileTransferState.transferring);
    expect(tasks.firstWhere((task) => task.fileName == 'b.txt').state, FileTransferState.pending);

    //释放第一个任务后第二个自动开始，完成的任务立即移除
    directChannel.releaseAt(0);
    await _settle();
    expect(directChannel.sent.length, 2);
    tasks = container.read(fileTransferProvider);
    expect(tasks.any((task) => task.fileName == 'a.txt'), isFalse);
    expect(tasks.firstWhere((task) => task.fileName == 'b.txt').state, FileTransferState.transferring);
  });

  test('取消排队中的任务直接置为已取消，不影响进行中的任务', () async {
    final baseDev = BaseDeviceInfo.fromDevice(_device('dev-1'));
    registry.addDevice(baseDev, TransportProtocol.direct, AppVersion('1.0.0', '100'), AppVersion('1.0.0', '100'));
    final notifier = container.read(fileTransferProvider.notifier);
    await notifier.sendFiles(baseDev, [_pending('a.txt'), _pending('b.txt')]);
    await _settle();

    final pendingTask = container.read(fileTransferProvider).firstWhere((task) => task.fileName == 'b.txt');
    notifier.cancelTask(pendingTask.id);
    await _settle();

    final tasks = container.read(fileTransferProvider);
    expect(tasks.firstWhere((task) => task.fileName == 'b.txt').state, FileTransferState.canceled);
    expect(tasks.firstWhere((task) => task.fileName == 'a.txt').state, FileTransferState.transferring);
  });

  test('取消传输中的任务经取消令牌中断后置为已取消', () async {
    final baseDev = BaseDeviceInfo.fromDevice(_device('dev-1'));
    registry.addDevice(baseDev, TransportProtocol.direct, AppVersion('1.0.0', '100'), AppVersion('1.0.0', '100'));
    final notifier = container.read(fileTransferProvider.notifier);
    await notifier.sendFiles(baseDev, [_pending('a.txt')]);
    await _settle();

    final task = container.read(fileTransferProvider).firstWhere((task) => task.fileName == 'a.txt');
    notifier.cancelTask(task.id);
    directChannel.releaseAt(0);
    await _settle();

    expect(container.read(fileTransferProvider).first.state, FileTransferState.canceled);
  });

  test('组级终止作用于同组全部任务', () async {
    final baseDev = BaseDeviceInfo.fromDevice(_device('dev-1'));
    registry.addDevice(baseDev, TransportProtocol.direct, AppVersion('1.0.0', '100'), AppVersion('1.0.0', '100'));
    final notifier = container.read(fileTransferProvider.notifier);
    await notifier.sendFiles(baseDev, [
      _pending('a.png', dirs: ['photos']),
      _pending('b.png', dirs: ['photos']),
    ]);
    await _settle();

    notifier.cancelGroup(.send, 'dev-1', 'photos');
    directChannel.releaseAt(0);
    await _settle();

    final tasks = container.read(fileTransferProvider);
    expect(tasks.every((task) => task.state == .canceled || task.state == .done), isTrue);
    //第一个任务释放时取消令牌已生效，两个任务都不应处于传输中
    expect(tasks.every((task) => task.state != .transferring), isTrue);
  });

  test('不同设备并行发送，互不阻塞', () async {
    for (final guid in ['dev-1', 'dev-2']) {
      final baseDev = BaseDeviceInfo.fromDevice(_device(guid));
      registry.addDevice(baseDev, TransportProtocol.direct, AppVersion('1.0.0', '100'), AppVersion('1.0.0', '100'));
    }
    final notifier = container.read(fileTransferProvider.notifier);
    await notifier.sendFiles(BaseDeviceInfo.fromDevice(_device('dev-1')), [_pending('a.txt')]);
    await notifier.sendFiles(BaseDeviceInfo.fromDevice(_device('dev-2')), [_pending('b.txt')]);
    await _settle();

    //两个设备各有任务同时在传输
    expect(directChannel.sent.length, 2);
    final states = container.read(fileTransferProvider).map((task) => task.state).toSet();
    expect(states, {FileTransferState.transferring});
  });

  test('协议未知的设备不创建任务', () async {
    final baseDev = BaseDeviceInfo.fromDevice(_device('dev-x'));
    await container.read(fileTransferProvider.notifier).sendFiles(baseDev, [_pending('a.txt')]);
    await _settle();

    expect(container.read(fileTransferProvider), isEmpty);
    expect(directChannel.sent, isEmpty);
  });

  test('清除仅移除已取消与失败的任务', () async {
    final baseDev = BaseDeviceInfo.fromDevice(_device('dev-1'));
    registry.addDevice(baseDev, TransportProtocol.direct, AppVersion('1.0.0', '100'), AppVersion('1.0.0', '100'));
    final notifier = container.read(fileTransferProvider.notifier);
    await notifier.sendFiles(baseDev, [_pending('a.txt'), _pending('b.txt')]);
    await _settle();

    notifier.clearFailed(.send);
    await _settle();
    //全部仍在排队/传输中，无可清除项
    expect(container.read(fileTransferProvider).length, 2);

    final pendingTask = container.read(fileTransferProvider).firstWhere((task) => task.fileName == 'b.txt');
    notifier.cancelTask(pendingTask.id);
    notifier.clearFailed(.send);
    await _settle();
    //已取消的 b 被清除，进行中的 a 保留
    final remaining = container.read(fileTransferProvider);
    expect(remaining.length, 1);
    expect(remaining.first.fileName, 'a.txt');
  });
}
