import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:clipshare/app/data/enums/forward_way.dart';
import 'package:clipshare/app/data/enums/history_content_type.dart';
import 'package:clipshare/app/data/enums/module.dart';
import 'package:clipshare/app/data/enums/op_method.dart';
import 'package:clipshare/app/data/enums/transport_protocol.dart';
import 'package:clipshare/app/data/models/dev_info.dart';
import 'package:clipshare/app/data/models/storage/web_dav_config.dart';
import 'package:clipshare/app/data/models/version.dart';
import 'package:clipshare/app/data/enums/forward_server_status.dart';
import 'package:clipshare/app/data/repository/dao/device_dao.dart';
import 'package:clipshare/app/data/repository/dao/operation_record_dao.dart';
import 'package:clipshare/app/data/repository/dao/operation_sync_dao.dart';
import 'package:clipshare/app/data/repository/dao/pending_storage_ack_dao.dart';
import 'package:clipshare/app/data/repository/entity/tables/app_info.dart';
import 'package:clipshare/app/data/repository/entity/tables/device.dart';
import 'package:clipshare/app/data/repository/entity/tables/history.dart';
import 'package:clipshare/app/data/repository/entity/tables/operation_record.dart';
import 'package:clipshare/app/data/repository/entity/tables/operation_sync.dart';
import 'package:clipshare/app/data/repository/entity/tables/pending_storage_ack.dart';
import 'package:clipshare/app/data/models/websocket/ws_msg_data.dart';
import 'package:clipshare/app/data/models/websocket/ws_msg_type.dart';
import 'package:clipshare/app/handlers/sync/abstract_data_sender.dart';
import 'package:clipshare/app/listeners/dev_alive_listener.dart';
import 'package:clipshare/app/listeners/forward_status_listener.dart';
import 'package:clipshare/app/listeners/sync_listener.dart';
import 'package:clipshare/app/modules/device_module/device_controller.dart';
import 'package:clipshare/app/modules/history_module/history_controller.dart';
import 'package:clipshare/app/services/clipboard_source_service.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/services/device_connection_notify_service.dart';
import 'package:clipshare/app/services/device_service.dart';
import 'package:clipshare/app/services/history_sync_progress_service.dart';
import 'package:clipshare/app/services/transport/connection_registry_service.dart';
import 'package:clipshare/app/services/transport/socket_service.dart';
import 'package:clipshare/app/services/transport/storage_service.dart';
import 'package:clipshare/app/services/transport/transport_heartbeat_service.dart';
import 'package:clipshare/app/utils/snowflake.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:msgpack_dart/msgpack_dart.dart' as m2;

import 'test_storage_ws_server.dart';

void main() {
  group('StorageService missing data replay', () {
    late ConnectionRegistryService connectionRegistryService;
    late DeviceConnectionRegistry registry;
    late _TestConfigService configService;
    late TestStorageWsServer wsServer;
    late _TestWebDavServer webDavServer;
    late StorageService storageService;
    late _RecordingSyncListener historySyncListener;
    late _TestDbService dbService;
    late _RecordingForwardStatusListener forwardStatusListener;
    late _RecordingDevAliveListener devAliveListener;
    late _RecordingDeviceConnectionNotifyService notifyService;

    const selfDevId = 'device-a';
    const peerDevId = 'device-b';
    const baselineDate = '2026-06-29';
    const baselineId = 1001;
    const missingId = 1002;

    setUp(() async {
      Get.testMode = true;
      connectionRegistryService = ConnectionRegistryService();
      registry = connectionRegistryService.registry;
      wsServer = TestStorageWsServer();
      await wsServer.start();
      webDavServer = _TestWebDavServer();
      await webDavServer.start();
      configService = _TestConfigService(
        selfDevId: selfDevId,
        wsBaseUri: wsServer.uri,
        webDavBaseUri: webDavServer.uri,
      );
      dbService = _TestDbService(
        latestStorageSyncRecordByDevId: <String, OperationRecord>{
          peerDevId: _buildOpRecord(
            id: baselineId,
            devId: peerDevId,
            data: baselineId.toString(),
            time: '$baselineDate 08:00:00.000',
          ),
        },
        deviceById: <String, Device>{
          selfDevId: configService.device,
          peerDevId: _buildDevice(peerDevId, 'Peer Device'),
        },
      );
      historySyncListener = _RecordingSyncListener();
      forwardStatusListener = _RecordingForwardStatusListener();
      devAliveListener = _RecordingDevAliveListener();

      Get.put<ConfigService>(configService);
      Get.put<ConnectionRegistryService>(connectionRegistryService);
      Get.put<DbService>(dbService);
      notifyService = _RecordingDeviceConnectionNotifyService();
      Get.put<DeviceConnectionNotifyService>(notifyService);
      Get.put<DeviceService>(
        _TestDeviceService(
          configService: configService,
          deviceById: dbService.deviceById,
        ),
      );
      Get.put<HistorySyncProgressService>(_TestHistorySyncProgressService());
      Get.put<ClipboardSourceService>(_TestClipboardSourceService());
      Get.put<TransportHeartbeatService>(TransportHeartbeatService().init());
      Get.put<SocketService>(_TestSocketService(registry));
      Get.put<DeviceController>(_TestDeviceController());
      Get.put<HistoryController>(_TestHistoryController());

      storageService = StorageService(registry);
      Get.put<StorageService>(storageService);
      connectionRegistryService.addForwardStatusListener(forwardStatusListener);
      connectionRegistryService.addDevAliveListener(devAliveListener);
      DataSender.addSyncListener(Module.history, historySyncListener);

      await webDavServer.writeJson(
        '/clipshare/devices-info/$peerDevId/deviceInfo.json',
        _buildDevice(peerDevId, 'Peer Device').toJson(),
      );
      await webDavServer.writeJson(
        '/clipshare/devices-info/$peerDevId/version.json',
        const AppVersion('1.0.0', '10').toJson(),
      );
      await webDavServer.writeJson(
        '/clipshare/devices-info/$peerDevId/minVersion.json',
        const AppVersion('1.0.0', '1').toJson(),
      );
      await webDavServer.createDirectory('/clipshare/app-info/$peerDevId');
      await webDavServer.writeBytes(
        '/clipshare/history/$peerDevId/$baselineDate/$baselineId',
        _encodeHistorySyncPayload(
          _buildHistory(
            id: baselineId,
            devId: peerDevId,
            time: '$baselineDate 08:00:00.000',
            content: 'baseline',
          ),
        ),
      );
    });

    tearDown(() async {
      DataSender.removeSyncListener(Module.history, historySyncListener);
      if (Get.isRegistered<ConnectionRegistryService>()) {
        connectionRegistryService.removeForwardStatusListener(
          forwardStatusListener,
        );
        connectionRegistryService.removeDevAliveListener(devAliveListener);
      }
      if (Get.isRegistered<StorageService>()) {
        await storageService.stop();
      }
      await wsServer.dispose();
      await webDavServer.dispose();
      Get.reset();
    });

    test('ws connected 后会扫描并补拉缺失历史记录', () async {
      final sessionFuture = wsServer.acceptedSessions.stream.first;
      await storageService.start();
      final firstSession = await sessionFuture;
      await _pumpAsyncQueue();
      historySyncListener.clear();

      await webDavServer.writeBytes(
        '/clipshare/history/$peerDevId/$baselineDate/$missingId',
        _encodeHistorySyncPayload(
          _buildHistory(
            id: missingId,
            devId: peerDevId,
            time: '$baselineDate 09:00:00.000',
            content: 'catch-up-on-connect',
          ),
        ),
      );
      await firstSession.close(
        WebSocketStatus.normalClosure,
        'reconnect for missing data replay',
      );
      await Future<void>.delayed(const Duration(milliseconds: 5300));

      expect(historySyncListener.syncedHistoryIds, contains(missingId));
    });

    test('启动存储中转时状态顺序为 initializing -> connecting -> connected', () async {
      await storageService.start();
      await _pumpAsyncQueue();

      expect(
        forwardStatusListener.statuses,
        <ForwardServerStatus>[
          ForwardServerStatus.initializing,
          ForwardServerStatus.connecting,
          ForwardServerStatus.connected,
        ],
      );
    });

    test('ws connected 后会刷新通知服务版本号', () async {
      await storageService.start();
      await _pumpAsyncQueue();

      expect(configService.transportServerVersion.value, wsServer.version);
    });

    test('通知服务版本低于 1.1.0 时不会建立 storage ws 连接', () async {
      wsServer.version = '1.0.9';

      await storageService.start();
      await _pumpAsyncQueue();

      expect(wsServer.sessions, isEmpty);
      expect(configService.transportServerVersion.value, '1.0.9');
      expect(
        forwardStatusListener.statuses,
        <ForwardServerStatus>[
          ForwardServerStatus.initializing,
          ForwardServerStatus.disconnected,
        ],
      );
    });

    test('通知服务版本解析失败时保持允许 storage ws 连接', () async {
      wsServer.version = 'invalid';

      await storageService.start();
      await _pumpAsyncQueue();

      expect(wsServer.sessions, isNotEmpty);
      expect(configService.transportServerVersion.value, 'invalid');
    });

    test('初始化阶段失败时状态从 initializing 落到 disconnected', () async {
      final today = DateTime.now().toString().split(' ').first;
      webDavServer.failMkCol('/clipshare/history/$selfDevId/$today');

      await storageService.start();
      await _pumpAsyncQueue();

      expect(
        forwardStatusListener.statuses,
        <ForwardServerStatus>[
          ForwardServerStatus.initializing,
          ForwardServerStatus.disconnected,
        ],
      );
    });

    test('B 断开期间新增历史后重新 online，A 应补拉缺失历史记录', () async {
      final sessionFuture = wsServer.acceptedSessions.stream.first;
      await storageService.start();
      final session = await sessionFuture;
      await _pumpAsyncQueue();
      historySyncListener.clear();

      await session.send(
        jsonEncode(WsMsgData(WsMsgType.offline, '', peerDevId).toJson()),
      );
      await webDavServer.writeBytes(
        '/clipshare/history/$peerDevId/$baselineDate/$missingId',
        _encodeHistorySyncPayload(
          _buildHistory(
            id: missingId,
            devId: peerDevId,
            time: '$baselineDate 10:00:00.000',
            content: 'created-while-offline',
          ),
        ),
      );
      await session.send(
        jsonEncode(
          WsMsgData(
            WsMsgType.online,
            jsonEncode(<String, dynamic>{
              'ipList': <String>[],
              'port': 9527,
            }),
            peerDevId,
          ).toJson(),
        ),
      );
      await _pumpAsyncQueue();

      await _waitForHistorySync(historySyncListener, missingId);
      expect(notifyService.connectedDevIds, contains(peerDevId));
    });

    test('收到 offline 后会同步清理连接注册表和离线通知', () async {
      final sessionFuture = wsServer.acceptedSessions.stream.first;
      await storageService.start();
      final session = await sessionFuture;
      await _pumpAsyncQueue();

      await session.send(
        jsonEncode(
          WsMsgData(
            WsMsgType.online,
            jsonEncode(<String, dynamic>{
              'ipList': <String>[],
              'port': 9527,
            }),
            peerDevId,
          ).toJson(),
        ),
      );
      await _pumpAsyncQueue();
      expect(registry.hasDevice(peerDevId), isTrue);

      await session.send(
        jsonEncode(WsMsgData(WsMsgType.offline, '', peerDevId).toJson()),
      );
      await _pumpAsyncQueue();

      expect(registry.hasDevice(peerDevId), isFalse);
      expect(devAliveListener.disconnectedDevIds, contains(peerDevId));
      expect(notifyService.disconnectedDevIds, contains(peerDevId));
    });

    test('未注册在线设备收到 offline 时不会触发断开通知', () async {
      const unregisteredDevId = 'device-c';
      final sessionFuture = wsServer.acceptedSessions.stream.first;
      await storageService.start();
      final session = await sessionFuture;
      await _pumpAsyncQueue();

      await session.send(
        jsonEncode(
          WsMsgData(WsMsgType.offline, '', unregisteredDevId).toJson(),
        ),
      );
      await _pumpAsyncQueue();

      expect(registry.hasDevice(unregisteredDevId), isFalse);
      expect(notifyService.disconnectedDevIds, isEmpty);
    });

    test('手动断开 storage 设备时不触发断开通知', () async {
      final sessionFuture = wsServer.acceptedSessions.stream.first;
      await storageService.start();
      final session = await sessionFuture;
      await _pumpAsyncQueue();

      await session.send(
        jsonEncode(
          WsMsgData(
            WsMsgType.online,
            jsonEncode(<String, dynamic>{
              'ipList': <String>[],
              'port': 9527,
            }),
            peerDevId,
          ).toJson(),
        ),
      );
      await _pumpAsyncQueue();
      notifyService.clear();

      storageService.disconnectDevice(peerDevId);
      await _pumpAsyncQueue();

      expect(registry.hasDevice(peerDevId), isFalse);
      expect(notifyService.disconnectedDevIds, isEmpty);
    });

    test('收到设备 online 后只补发该设备的 pending storage ACK', () async {
      const otherDevId = 'device-c';
      dbService.pendingStorageAckDao.items.addAll(<PendingStorageAck>[
        PendingStorageAck(opId: 2001, targetDevId: peerDevId),
        PendingStorageAck(opId: 2002, targetDevId: otherDevId),
      ]);
      final sessionFuture = wsServer.acceptedSessions.stream.first;
      await storageService.start();
      final session = await sessionFuture;
      await _pumpAsyncQueue();
      // 启动时的缺失数据扫描可能已经注册设备，这里明确模拟首次 online 前未连接。
      registry.removeDevice(peerDevId);
      final ackFuture = _waitForWsMessage(
        wsServer,
        (msg) =>
            msg.operation == WsMsgType.ack && msg.targetDevId == peerDevId,
      );

      await session.send(
        jsonEncode(
          WsMsgData(
            WsMsgType.online,
            jsonEncode(<String, dynamic>{
              'ipList': <String>['127.0.0.1'],
              'port': wsServer.uri.port,
            }),
            peerDevId,
          ).toJson(),
        ),
      );
      final ack = await ackFuture;
      final payload = jsonDecode(ack.data) as Map<String, dynamic>;

      expect(ack.targetDevId, peerDevId);
      expect(payload['opId'], 2001);
      expect(payload['devId'], selfDevId);
      expect(
        dbService.pendingStorageAckDao.items.map((item) => item.opId),
        contains(2002),
      );
      expect(
        dbService.pendingStorageAckDao.items.map((item) => item.opId),
        isNot(contains(2001)),
      );

      final repeatedAckMessages = <WsMsgData>[];
      final subscription = wsServer.receivedMessages.stream.listen((raw) {
        final message = WsMsgData.fromJson(
          (jsonDecode(raw) as Map<dynamic, dynamic>).cast<String, dynamic>(),
        );
        if (message.operation == WsMsgType.ack &&
            message.targetDevId == peerDevId) {
          repeatedAckMessages.add(message);
        }
      });
      await session.send(
        jsonEncode(
          WsMsgData(
            WsMsgType.online,
            jsonEncode(<String, dynamic>{
              'ipList': <String>[],
              'port': 9527,
            }),
            peerDevId,
          ).toJson(),
        ),
      );
      await _pumpAsyncQueue();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await subscription.cancel();
      expect(repeatedAckMessages, isEmpty);
    });

    test('收到 storage ACK 后写入 OperationSync', () async {
      final sessionFuture = wsServer.acceptedSessions.stream.first;
      await storageService.start();
      final session = await sessionFuture;
      await _pumpAsyncQueue();

      await session.send(
        jsonEncode(
          WsMsgData(
            WsMsgType.ack,
            jsonEncode(<String, dynamic>{'opId': 3001, 'devId': peerDevId}),
            peerDevId,
          ).toJson(),
        ),
      );
      await _pumpAsyncQueue();

      expect(
        dbService.operationSyncDao.items,
        contains(
          isA<OperationSync>()
              .having((item) => item.opId, 'opId', 3001)
              .having((item) => item.devId, 'devId', peerDevId)
              .having((item) => item.uid, 'uid', configService.userId),
        ),
      );
    });

    test('有效 socket 未配对结论会阻止 storage 重新标记 paired', () async {
      final deviceService = Get.find<DeviceService>();
      final socketDevice = Device(
        guid: peerDevId,
        devName: 'Peer Device',
        uid: configService.userId,
        type: 'android',
      );
      dbService.deviceById.remove(peerDevId);

      // socket 已完成 pairedStatus 交换后，本地无记录等价于本地未配对。
      final socketResult = await deviceService.confirmPairingState(
        device: socketDevice,
        localIsPaired: false,
        remoteIsPaired: true,
        protocol: TransportProtocol.direct,
      );
      expect(socketResult.accepted, isTrue);
      expect(dbService.deviceById[peerDevId]?.isPaired, isFalse);

      final sessionFuture = wsServer.acceptedSessions.stream.first;
      await storageService.start();
      final session = await sessionFuture;
      await _pumpAsyncQueue();

      await session.send(
        jsonEncode(
          WsMsgData(
            WsMsgType.online,
            jsonEncode(<String, dynamic>{
              'ipList': <String>[],
              'port': 9527,
            }),
            peerDevId,
          ).toJson(),
        ),
      );
      await _pumpAsyncQueue();

      expect(dbService.deviceById[peerDevId]?.isPaired, isFalse);
      expect(notifyService.connectedDevIds, isNot(contains(peerDevId)));
    });

    test('ws 整体断开时即使没有额外 listener 也会清理连接注册表', () async {
      connectionRegistryService.removeDevAliveListener(devAliveListener);

      final sessionFuture = wsServer.acceptedSessions.stream.first;
      await storageService.start();
      final session = await sessionFuture;
      await _pumpAsyncQueue();

      await session.send(
        jsonEncode(
          WsMsgData(
            WsMsgType.online,
            jsonEncode(<String, dynamic>{
              'ipList': <String>[],
              'port': 9527,
            }),
            peerDevId,
          ).toJson(),
        ),
      );
      await _pumpAsyncQueue();
      expect(registry.hasDevice(peerDevId), isTrue);

      await session.close(
        WebSocketStatus.goingAway,
        'disconnect registry cleanup',
      );
      await Future<void>.delayed(const Duration(milliseconds: 300));

      expect(registry.hasDevice(peerDevId), isFalse);
    });

    test(
      'manual storage ws disconnect sends offline then notifies disconnected',
      () async {
        final sessionFuture = wsServer.acceptedSessions.stream.first;
        await storageService.start();
        final session = await sessionFuture;
        await _pumpAsyncQueue();

        await session.send(
          jsonEncode(
            WsMsgData(
              WsMsgType.online,
              jsonEncode(<String, dynamic>{
                'ipList': <String>[],
                'port': 9527,
              }),
              peerDevId,
            ).toJson(),
          ),
        );
        await _pumpAsyncQueue();
        expect(registry.hasDevice(peerDevId), isTrue);
        devAliveListener.disconnectedDevIds.clear();

        final offlineFuture = _waitForWsMessage(
          wsServer,
          (msg) =>
              msg.operation == WsMsgType.offline &&
              msg.targetDevId == peerDevId,
        );
        await storageService.disconnectWs();
        final offlineMsg = await offlineFuture;
        await _pumpAsyncQueue();

        expect(offlineMsg.targetDevId, peerDevId);
        expect(registry.hasDevice(peerDevId), isFalse);
        expect(devAliveListener.disconnectedDevIds, contains(peerDevId));
      },
    );

    test('storage ws disconnect keeps socket devices registered', () async {
      const socketDevId = 'device-c';
      registry.addDevice(
        DevInfo(socketDevId, 'Socket Device', 'android'),
        TransportProtocol.direct,
      );
      final sessionFuture = wsServer.acceptedSessions.stream.first;
      await storageService.start();
      final session = await sessionFuture;
      await _pumpAsyncQueue();

      await session.send(
        jsonEncode(
          WsMsgData(
            WsMsgType.online,
            jsonEncode(<String, dynamic>{
              'ipList': <String>[],
              'port': 9527,
            }),
            peerDevId,
          ).toJson(),
        ),
      );
      await _pumpAsyncQueue();
      expect(registry.hasDevice(peerDevId), isTrue);
      expect(registry.hasDevice(socketDevId), isTrue);
      devAliveListener.disconnectedDevIds.clear();

      await session.close(WebSocketStatus.goingAway, 'storage disconnect only');
      await Future<void>.delayed(const Duration(milliseconds: 300));

      expect(registry.hasDevice(peerDevId), isFalse);
      expect(registry.hasDevice(socketDevId), isTrue);
      expect(devAliveListener.disconnectedDevIds, contains(peerDevId));
      expect(devAliveListener.disconnectedDevIds, isNot(contains(socketDevId)));
    });

    test('socket 在线时 storage offline 不会清理 socket 注册状态', () async {
      registry.addDevice(
        DevInfo(peerDevId, 'Peer Device', 'android'),
        TransportProtocol.direct,
      );
      final sessionFuture = wsServer.acceptedSessions.stream.first;
      await storageService.start();
      final session = await sessionFuture;
      await _pumpAsyncQueue();
      devAliveListener.disconnectedDevIds.clear();
      notifyService.clear();

      await session.send(
        jsonEncode(WsMsgData(WsMsgType.offline, '', peerDevId).toJson()),
      );
      await _pumpAsyncQueue();

      expect(registry.hasDevice(peerDevId), isTrue);
      expect(registry.getProtocol(peerDevId), TransportProtocol.direct);
      expect(devAliveListener.disconnectedDevIds, isNot(contains(peerDevId)));
      expect(notifyService.disconnectedDevIds, isNot(contains(peerDevId)));
    });

    test('socket 在线时 storage online 不会覆盖 socket 协议', () async {
      final socketService = Get.find<SocketService>() as _TestSocketService;
      socketService.onlineResults[peerDevId] = true;
      registry.addDevice(
        DevInfo(peerDevId, 'Peer Device', 'android'),
        TransportProtocol.direct,
      );
      final sessionFuture = wsServer.acceptedSessions.stream.first;
      await storageService.start();
      final session = await sessionFuture;
      await _pumpAsyncQueue();
      notifyService.clear();

      await session.send(
        jsonEncode(
          WsMsgData(
            WsMsgType.online,
            jsonEncode(<String, dynamic>{
              'ipList': <String>[],
              'port': 9527,
            }),
            peerDevId,
          ).toJson(),
        ),
      );
      await _pumpAsyncQueue();

      expect(registry.hasDevice(peerDevId), isTrue);
      expect(registry.getProtocol(peerDevId), TransportProtocol.direct);
      expect(socketService.testedDevIds, contains(peerDevId));
      expect(notifyService.connectedDevIds, isEmpty);
    });

    test('socket 探活失败后后续 storage online 可以恢复 storage 协议', () async {
      final socketService = Get.find<SocketService>() as _TestSocketService;
      socketService.onlineResults[peerDevId] = false;
      registry.addDevice(
        DevInfo(peerDevId, 'Peer Device', 'android'),
        TransportProtocol.direct,
      );
      final sessionFuture = wsServer.acceptedSessions.stream.first;
      await storageService.start();
      final session = await sessionFuture;
      await _pumpAsyncQueue();
      notifyService.clear();

      await session.send(
        jsonEncode(
          WsMsgData(
            WsMsgType.online,
            jsonEncode(<String, dynamic>{
              'ipList': <String>[],
              'port': 9527,
            }),
            peerDevId,
          ).toJson(),
        ),
      );
      await _waitForProtocol(registry, peerDevId, TransportProtocol.webdav);

      expect(socketService.testedDevIds, contains(peerDevId));
      expect(registry.hasDevice(peerDevId), isTrue);
      expect(registry.getProtocol(peerDevId), TransportProtocol.webdav);
      expect(notifyService.connectedDevIds, contains(peerDevId));
    });

    test('socket 断开清理后后续 storage online 可以恢复 storage 协议', () async {
      registry.addDevice(
        DevInfo(peerDevId, 'Peer Device', 'android'),
        TransportProtocol.direct,
      );
      final sessionFuture = wsServer.acceptedSessions.stream.first;
      await storageService.start();
      final session = await sessionFuture;
      await _pumpAsyncQueue();
      registry.removeDevice(peerDevId);
      notifyService.clear();

      await session.send(
        jsonEncode(
          WsMsgData(
            WsMsgType.online,
            jsonEncode(<String, dynamic>{
              'ipList': <String>[],
              'port': 9527,
            }),
            peerDevId,
          ).toJson(),
        ),
      );
      await _pumpAsyncQueue();

      expect(registry.hasDevice(peerDevId), isTrue);
      expect(registry.getProtocol(peerDevId), TransportProtocol.webdav);
      expect(notifyService.connectedDevIds, contains(peerDevId));
    });
  });
}

Future<void> _pumpAsyncQueue() async {
  await Future<void>.delayed(const Duration(milliseconds: 100));
}

/// 轮询等待异步补拉完成，避免把断言绑定到固定毫秒延时上。
Future<void> _waitForHistorySync(
  _RecordingSyncListener listener,
  int historyId,
) async {
  final stopwatch = Stopwatch()..start();
  while (stopwatch.elapsed < const Duration(seconds: 2)) {
    if (listener.syncedHistoryIds.contains(historyId)) {
      return;
    }
    await _pumpAsyncQueue();
  }
  expect(listener.syncedHistoryIds, contains(historyId));
}

Future<void> _waitForProtocol(
  DeviceConnectionRegistry registry,
  String devId,
  TransportProtocol protocol,
) async {
  final stopwatch = Stopwatch()..start();
  while (stopwatch.elapsed < const Duration(seconds: 5)) {
    if (registry.getProtocol(devId) == protocol) {
      return;
    }
    await _pumpAsyncQueue();
  }
  expect(registry.getProtocol(devId), protocol);
}

/// 等待指定 websocket 消息，避免测试依赖固定延迟或误读初始化阶段的 online 消息。
Future<WsMsgData> _waitForWsMessage(
  TestStorageWsServer server,
  bool Function(WsMsgData msg) predicate,
) async {
  final completer = Completer<WsMsgData>();
  late final StreamSubscription<String> subscription;
  subscription = server.receivedMessages.stream.listen((raw) {
    final msg = WsMsgData.fromJson(
      (jsonDecode(raw) as Map<dynamic, dynamic>).cast<String, dynamic>(),
    );
    if (!completer.isCompleted && predicate(msg)) {
      completer.complete(msg);
    }
  });
  try {
    return await completer.future.timeout(const Duration(seconds: 2));
  } finally {
    await subscription.cancel();
  }
}

OperationRecord _buildOpRecord({
  required int id,
  required String devId,
  required String data,
  required String time,
}) {
  final record = OperationRecord(
    id: id,
    uid: 1,
    devId: devId,
    module: Module.history,
    moduleEn: Module.history.name,
    method: OpMethod.add,
    data: data,
    storageSync: true,
  );
  record.time = time;
  return record;
}

Device _buildDevice(String guid, String name) {
  return Device(
    guid: guid,
    devName: name,
    uid: 1,
    type: 'android',
    isPaired: true,
  );
}

History _buildHistory({
  required int id,
  required String devId,
  required String time,
  required String content,
}) {
  return History(
    id: id,
    uid: 1,
    time: time,
    content: content,
    type: HistoryContentType.text.value,
    devId: devId,
    size: content.length,
    sync: true,
  );
}

Uint8List _encodeHistorySyncPayload(History history) {
  return Uint8List.fromList(
    m2.serialize(<String, dynamic>{
      'module': Module.history.name,
      'moduleEn': Module.history.name,
      'method': OpMethod.add.name,
      'data': history.toJson(),
      'id': history.id,
      'uid': history.uid,
      'devId': history.devId,
      'time': history.time,
      'storageSync': true,
    }),
  );
}

class _TestConfigService extends GetxService implements ConfigService {
  @override
  final Device device;

  @override
  final AppVersion version = const AppVersion('1.0.0', '10');

  @override
  final AppVersion minVersion = const AppVersion('1.0.0', '1');

  @override
  final Snowflake snowflake = Snowflake(1);

  @override
  final transportServerVersion = ''.obs;

  final Uri wsBaseUri;
  final Uri webDavBaseUri;

  _TestConfigService({
    required String selfDevId,
    required this.wsBaseUri,
    required this.webDavBaseUri,
  }) : device = Device(
         guid: selfDevId,
         devName: 'Self Device',
         uid: 1,
         type: 'android',
         isPaired: true,
       );

  @override
  bool get enableStorageSync => true;

  @override
  bool get enableForward => true;

  @override
  bool get enableWebDAV => true;

  @override
  bool get enableS3 => false;

  @override
  bool get autoSyncMissingData => true;

  @override
  int get userId => 1;

  @override
  int get port => 9527;

  @override
  int get heartbeatInterval => 60;

  @override
  bool get autoCloseConnAfterScreenOff => false;

  @override
  String get localName => 'Self Device';

  @override
  String get notificationServer => wsBaseUri.toString();

  @override
  ForwardWay get forwardWay => ForwardWay.webdav;

  @override
  WebDAVConfig? get webDAVConfig => WebDAVConfig(
    server: webDavBaseUri.toString(),
    username: 'tester',
    password: 'secret',
    baseDir: '/clipshare',
    displayName: 'test-webdav',
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestDbService extends DbService {
  final Map<String, OperationRecord> latestStorageSyncRecordByDevId;
  final Map<String, Device> deviceById;
  OperationRecordDao? _operationRecordDao;
  DeviceDao? _deviceDao;
  @override
  final _FakePendingStorageAckDao pendingStorageAckDao =
      _FakePendingStorageAckDao();
  final _FakeOperationSyncDao operationSyncDao = _FakeOperationSyncDao();

  _TestDbService({
    required this.latestStorageSyncRecordByDevId,
    required this.deviceById,
  });

  @override
  OperationRecordDao get opRecordDao => _operationRecordDao ??=
      _FakeOperationRecordDao(latestStorageSyncRecordByDevId);

  @override
  DeviceDao get deviceDao => _deviceDao ??= _FakeDeviceDao(deviceById);

  @override
  OperationSyncDao get opSyncDao => operationSyncDao;

  @override
  void execSequentially(Future Function() f) {
    unawaited(f());
  }
}

class _FakeOperationRecordDao extends OperationRecordDao {
  final Map<String, OperationRecord> latestStorageSyncRecordByDevId;

  _FakeOperationRecordDao(this.latestStorageSyncRecordByDevId);

  @override
  Future<OperationRecord?> getLatestStorageSyncSuccessByDevId(
    String devId,
  ) async {
    return latestStorageSyncRecordByDevId[devId];
  }

  @override
  Future<List<OperationRecord>> getStorageSyncFiledData(String devId) async {
    return const <OperationRecord>[];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeDeviceDao extends DeviceDao {
  final Map<String, Device> deviceById;

  _FakeDeviceDao(this.deviceById);

  @override
  Future<Device?> getById(String guid, int uid) async {
    return deviceById[guid];
  }

  @override
  Future<List<Device>> getAllDevices(int uid) async {
    return deviceById.values.toList(growable: false);
  }

  @override
  Future<int> add(Device dev) async {
    deviceById[dev.guid] = dev;
    return 1;
  }

  @override
  Future<int> updateDevice(Device dev) async {
    if (!deviceById.containsKey(dev.guid)) {
      return 0;
    }
    deviceById[dev.guid] = dev;
    return 1;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePendingStorageAckDao extends PendingStorageAckDao {
  final List<PendingStorageAck> items = <PendingStorageAck>[];

  @override
  Future<int> add(PendingStorageAck item) async {
    final exists = items.any(
      (current) =>
          current.opId == item.opId && current.targetDevId == item.targetDevId,
    );
    if (exists) {
      return 0;
    }
    items.add(item);
    return 1;
  }

  @override
  Future<List<PendingStorageAck>> getByTargetDevId(String targetDevId) async {
    return items
        .where((item) => item.targetDevId == targetDevId)
        .toList(growable: false);
  }

  @override
  Future<int?> remove(PendingStorageAck item) {
    return removeByKey(item.opId, item.targetDevId);
  }

  @override
  Future<int?> removeByKey(int opId, String targetDevId) async {
    final before = items.length;
    items.removeWhere(
      (item) => item.opId == opId && item.targetDevId == targetDevId,
    );
    return before - items.length;
  }

  Future<List<PendingStorageAck>> getAll() async {
    return List<PendingStorageAck>.from(items);
  }
}

class _FakeOperationSyncDao extends OperationSyncDao {
  final List<OperationSync> items = <OperationSync>[];

  @override
  Future<int> add(OperationSync syncHistory) async {
    final exists = items.any(
      (item) =>
          item.opId == syncHistory.opId &&
          item.devId == syncHistory.devId &&
          item.uid == syncHistory.uid,
    );
    if (exists) {
      return 0;
    }
    items.add(syncHistory);
    return 1;
  }

  @override
  Future<List<OperationSync>> getAll() async {
    return List<OperationSync>.from(items);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestDeviceService extends DeviceService {
  final ConfigService configService;
  final Map<String, Device> deviceById;

  _TestDeviceService({
    required this.configService,
    required this.deviceById,
  });

  @override
  Device getById(String id) {
    final device = deviceById[id];
    if (device != null) {
      return device;
    }
    if (id == configService.device.guid) {
      return configService.device;
    }
    return Device.unknown;
  }
}

class _RecordingSyncListener implements SyncListener {
  final List<int> syncedHistoryIds = <int>[];

  void clear() {
    syncedHistoryIds.clear();
  }

  @override
  Future ackSync(dynamic msg) async {}

  @override
  Future onStorageSync(
    Map<String, dynamic> map,
    Device sender,
    bool loadingMissingData,
  ) async {
    final history = History.fromJson(
      (map['data'] as Map<dynamic, dynamic>).cast<String, dynamic>(),
    );
    syncedHistoryIds.add(history.id);
  }

  @override
  Future onSync(dynamic msg) async {}
}

/// 记录中转状态变化，供测试直接断言初始化阶段的可见状态顺序。
class _RecordingForwardStatusListener implements ForwardStatusListener {
  final List<ForwardServerStatus> statuses = <ForwardServerStatus>[];

  @override
  void onForwardServerStatusChanged(ForwardServerStatus status) {
    statuses.add(status);
  }
}

/// 记录设备离线通知，便于断言离线收口是否完整触发。
class _RecordingDevAliveListener with DevAliveListener {
  final List<String> disconnectedDevIds = <String>[];

  @override
  void onDisconnected(String devId) {
    disconnectedDevIds.add(devId);
  }
}

/// 记录连接通知调用，避免单元测试触发真实系统通知。
class _RecordingDeviceConnectionNotifyService
    extends DeviceConnectionNotifyService {
  final List<String> connectedDevIds = <String>[];
  final List<String> disconnectedDevIds = <String>[];

  void clear() {
    connectedDevIds.clear();
    disconnectedDevIds.clear();
  }

  @override
  void showConnected(String devId, {required bool isPaired}) {
    if (isPaired) {
      connectedDevIds.add(devId);
    }
  }

  @override
  void showDisconnected(String devId, {required bool isPaired}) {
    if (isPaired) {
      disconnectedDevIds.add(devId);
    }
  }
}

class _TestHistorySyncProgressService extends HistorySyncProgressService {
  @override
  void addProgress(
    String devId,
    Map<String, dynamic>? syncData,
    int seq,
    int total,
    bool fromStorage,
  ) {}
}

class _TestClipboardSourceService extends ClipboardSourceService {
  @override
  List<AppInfo> get appInfos => const <AppInfo>[];
}

class _TestSocketService extends SocketService {
  final DeviceConnectionRegistry testRegistry;

  _TestSocketService(this.testRegistry) : super(testRegistry);

  final Map<String, bool> onlineResults = <String, bool>{};
  final List<String> testedDevIds = <String>[];

  @override
  bool get discovering => false;

  @override
  Future<bool> testIsOnline(String devId, {bool autoReconnect = true}) async {
    testedDevIds.add(devId);
    final online = onlineResults[devId] ?? false;
    if (!online) {
      testRegistry.removeDevice(devId);
    }
    return online;
  }
}

class _TestDeviceController extends GetxController implements DeviceController {
  @override
  List<Device> get onlineAndPairedList => const <Device>[];

  @override
  List<Device> get offlineAndPairedList => const <Device>[];

  @override
  List<Device> get onlineList => const <Device>[];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestHistoryController extends GetxController
    implements HistoryController {
  @override
  void setMissingDataCopyMsg(
    Map<String, dynamic> syncData, [
    bool fromStorage = false,
  ]) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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
  final Set<String> _mkColFailPaths = <String>{};

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

  /// 删除指定路径，便于测试构造初始化失败场景。
  Future<void> deletePath(String path) async {
    final normalizedPath = _normalize(path);
    _entries.removeWhere(
      (entryPath, _) =>
          entryPath == normalizedPath ||
          entryPath.startsWith('$normalizedPath/'),
    );
  }

  /// 为指定目录制造 MKCOL 失败，便于稳定复现初始化阶段错误。
  void failMkCol(String path) {
    _mkColFailPaths.add(_normalize(path));
  }

  Future<void> writeBytes(String path, List<int> bytes) async {
    final normalizedPath = _normalize(path);
    _ensureParentDirectories(normalizedPath);
    _entries[normalizedPath] = _StoredEntry.file(List<int>.from(bytes));
  }

  Future<void> _handleRequest(HttpRequest request) async {
    final path = _normalize(request.uri.path);
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
    if (_mkColFailPaths.contains(path)) {
      request.response.statusCode = HttpStatus.internalServerError;
      await request.response.close();
      return;
    }
    _ensureParentDirectories(path);
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
