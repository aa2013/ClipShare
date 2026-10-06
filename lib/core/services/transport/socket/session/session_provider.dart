import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/database/dao/device_dao.dart';
import 'package:clipshare/core/database/tables/device.dart';
import 'package:clipshare/core/database/app_database.dart';
import 'package:clipshare/core/services/clipboard/clipboard_source_provider.dart';
import 'package:clipshare/core/services/device/device_connection_notify_provider.dart';
import 'package:clipshare/core/services/device/device_pairing_provider.dart';
import 'package:clipshare/core/services/notify/notify_provider.dart';
import 'package:clipshare/core/services/transport/message_sender/message_sender.dart';
import 'package:clipshare/core/services/transport/message_sender/message_sender_provider.dart';
import 'package:clipshare/core/settings/sync/sync_settings.dart';
import 'package:clipshare/core/settings/sync/sync_settings_provider.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/models/module.dart';
import 'package:clipshare/shared/exceptions/device_not_connected_exception.dart';
import 'package:clipshare/shared/utils/crypto.dart';
import 'package:clipshare/shared/utils/dialog.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:clipshare/core/services/device/device_provider.dart';
import 'package:clipshare/core/services/device/events/device_lifecycle_event.dart';
import 'package:clipshare/core/services/rules/rules_provider.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:clipshare/core/constants/app_constants.dart';
import 'package:clipshare/core/services/transport/socket/session/reconnect_provider.dart';
import 'package:clipshare/core/services/transport/socket/forward/forward_server_provider.dart';
import 'package:clipshare/core/services/transport/heartbeat/transport_heartbeat_provider.dart';
import 'package:clipshare/shared/models/version.dart';
import 'package:clipshare/shared/enums/transport_protocol.dart';
import 'package:clipshare/shared/extensions/string_extension.dart';
import 'package:clipshare/core/services/transport/socket/session/device_socket_session_store.dart';
import 'package:clipshare/core/services/device/local_device_info.dart';
import 'package:clipshare/core/services/transport/socket/session/device_connection_queue.dart';
import '../../client/socket/secure_socket_client.dart';
import '../../models/message_data.dart';
import '../../enums/msg_type.dart';
import 'package:clipshare/core/services/device/local_device_info_provider.dart';
import 'package:clipshare/shared/utils/parallerl_task.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:collection/collection.dart';

part 'session_provider.g.dart';

part 'session_message_handler.dart';

/// 设备会话的公开入口。
@Riverpod(keepAlive: true)
class SessionNotifier extends _$SessionNotifier implements MessageSender {
  static const tag = 'SessionNotifier';
  static const _socketHeartbeatTaskName = 'socket-ping';
  final DeviceSocketSessionStore sessions = DeviceSocketSessionStore();
  late final DeviceConnectionQueue connectionQueue;
  bool _disposed = false;
  final Map<String, Future<bool>> _inFlightConnectionRequests = {};
  final Set<String> _pendingPairingAddresses = {};
  bool _pairing = false;
  int? _pairingNotifyId;

  TransportHeartbeatNotifier get _heartbeatNotifier => ref.read(transportHeartbeatProvider.notifier);

  DevicePairingCodeNotifier get _deviceParingCodeNotifier => ref.read(devicePairingCodeProvider.notifier);

  NotifyNotifier get _notifyNotifier => ref.read(notifyProvider.notifier);

  ForwardServerNotifier get _forwardServer => ref.read(forwardServerProvider.notifier);

  ReconnectNotifier get _reconnectNotifier => ref.read(reconnectProvider.notifier);

  DeviceNotifier get _deviceNotifier => ref.read(deviceProvider.notifier);

  DeviceConnectionNotifyNotifier get _deviceConnectionNotifier => ref.read(deviceConnectionNotifyProvider.notifier);

  DeviceState get _deviceState => ref.read(deviceProvider).requireValue;

  LocalDeviceInfo get _localDeviceInfo => ref.read(localDeviceInfoProvider).requireValue;

  BaseDeviceInfo get _self => _localDeviceInfo.baseDeviceInfo;

  DeviceDao get _deviceDao => ref.read(appDbProvider).requireValue.deviceDao;

  MessageSenderNotifier get _messageSender => ref.read(messageSenderProvider.notifier);

  SyncSettings get _syncSettings => ref.read(syncSettingsProvider).requireValue;

  @override
  void build() {
    connectionQueue = DeviceConnectionQueue(
      processor: processCandidate,
      idleTtl: const Duration(seconds: 15),
    );
    registerHeartbeatTask();
    startHeartbeatTest();
    ref.onDispose(() {
      _disposed = true;
      connectionQueue.close();
      _heartbeatNotifier.unregisterTask(_socketHeartbeatTaskName);
    });
  }

  /// 注册并启动会话集合的统一 Socket 心跳任务。
  void registerHeartbeatTask() {
    _heartbeatNotifier.registerTask(
      TransportHeartbeatTask(
        name: _socketHeartbeatTaskName,
        shouldRun: () => true,
        onTick: (trigger) {
          if (trigger == TransportHeartbeatTrigger.timer && sessions.isEmpty) {
            return;
          }
          if (trigger == TransportHeartbeatTrigger.timer) {
            logger.debug(tag, 'send ping');
          }
          _messageSender.sendToAll(.ping, {}, false);
        },
        onStop: (reason) {
          if (reason != .screenOffAutoClose) return;
          // 息屏到期时断开所有连接并停止中转服务存活判断。
          logger.debug(tag, '屏幕关闭时间已到，断开所有连接和心跳测试');
          disconnectAllConnections();
          _forwardServer.stopHeartbeatWatch();
        },
      ),
    );
  }

  /// 开始会话心跳检测。
  void startHeartbeatTest() => _heartbeatNotifier.start(_socketHeartbeatTaskName);

  /// 停止会话心跳检测。
  void stopHeartbeatTest() => _heartbeatNotifier.stop(_socketHeartbeatTaskName);

  /// 判断设备是否在线；会话集合是在线状态的唯一来源。
  bool isOnline(String devId, bool requiredPaired) => sessions.isOnline(devId, requiredPaired: requiredPaired);

  /// 返回设备当前会话是否使用中转连接。
  bool isUseForward(String devId) => sessions.get(devId)?.socket.isForwardMode ?? false;

  /// 探测设备在线状态。
  Future<bool> testIsOnline(String devId, {bool autoReconnect = true}) async {
    final session = sessions.get(devId);
    if (session == null) return false;
    if (await session.socket.testOnline()) return true;
    await closeSession(
      devId,
      session.socket,
      reason: 'online probe failed',
      autoReconnect: autoReconnect,
    );
    return false;
  }

  /// 断开设备连接。
  Future<bool> disconnectDevice(BaseDeviceInfo dev, bool backSend) async {
    final session = sessions.get(dev.guid);
    if (session == null) return false;
    await closeSession(
      dev.guid,
      session.socket,
      reason: 'disconnect',
      autoReconnect: false,
      sendDisconnect: backSend,
    );
    return true;
  }

  /// 断开全部设备连接。
  void disconnectAllConnections([bool onlyNotPaired = false]) {
    for (final session in sessions.snapshot()) {
      if (onlyNotPaired && session.isPaired) {
        continue;
      }
      unawaited(disconnectDevice(session.dev, true));
    }
  }

  /// 处理一个连接候选；连接逻辑由直连 Provider 提供，队列和会话状态由本 Provider 持有。
  /// 提交连接候选到会话串行队列。
  Future<bool> submitCandidate(DeviceConnectionRequest request) {
    final running = _inFlightConnectionRequests[request.workerKey];
    if (running != null) {
      return running;
    }
    final future = connectionQueue.enqueue(request);
    _inFlightConnectionRequests[request.workerKey] = future;
    future.whenComplete(() {
      if (identical(_inFlightConnectionRequests[request.workerKey], future)) {
        _inFlightConnectionRequests.remove(request.workerKey);
      }
    });
    return future;
  }

  /// 记录手动连接的候选地址，供后续配对消息确定持久化地址。
  void rememberPairingAddress(String address) => _pendingPairingAddresses.add(address);

  /// 处理已完成握手的客户端。
  /// 处理传输层断开。
  void onTransportClosed(SecureSocketClient client, {required String reason}) => handleTransportClosed(client, reason: reason);

  /// 转发 Socket 消息到会话处理器。
  Future<void> onSocketReceived(SecureSocketClient client, MessageData msg) => handleSocketMessage(client, msg);

  /// 关闭全部中转会话。
  Future<void> closeForwardSessions() async {
    for (final session in sessions.snapshot().where((item) => item.socket.isForwardMode)) {
      await closeSession(
        session.dev.guid,
        session.socket,
        reason: 'forward disconnected',
        autoReconnect: false,
      );
    }
  }

  /// 请求设备同步缺失数据，保留原有暂时屏蔽的同步实现。
  Future<void> requestMissingData([String? devId]) async {
    final clipboardSource = await ref.read(clipboardSourceProvider.future);
    if (devId != null) {
      final devSkt = sessions.get(devId);
      if (devSkt == null) return;
      final allAppInfos = clipboardSource.appInfos;
      final ownedAppIds = allAppInfos.where((item) => item.devId == devId).map((item) => item.appId).toList();
      await sendData(devSkt.dev, .reqMissingData, {
        'appIds': ownedAppIds,
      });
    } else {
      if (!_syncSettings.autoSyncMissingData) {
        return;
      }
      final devs = sessions.snapshot().where((dev) => dev.isPaired).map(((item) => item.dev)).toList();
      final allAppInfos = clipboardSource.appInfos;
      for (var dev in devs) {
        final ownedAppIds = allAppInfos.where((item) => item.devId == dev.guid).map((item) => item.appId).toList();
        await sendData(dev, .reqMissingData, {
          'appIds': ownedAppIds,
        });
      }
    }
  }

  /// 统一处理直连和中转收到的业务消息。
  Future<void> handleSocketMessage(SecureSocketClient client, MessageData msg) async {
    final dev = msg.send;
    logger.debug(tag, '${dev.name} ${msg.key}');
    final address = _pendingPairingAddresses.firstWhereOrNull((ip) => ip.split(':')[0] == client.ip);
    switch (msg.key) {
      case MsgType.disConnect:
        await closeSession(dev.guid, client, reason: 'remote disconnect', autoReconnect: false);
        break;
      case MsgType.forgetDev:
        await forgetDevice(dev);
        break;
      case MsgType.ackSync:
      case MsgType.sync:
        _onSyncMsg(this, msg);
        break;
      case MsgType.missingData:
        _onMissingData(this, msg);
        break;
      case MsgType.reqMissingData:
        _onRequestMissingData(this, msg);
        break;
      case MsgType.reqAppInfo:
        await _onRequestAppInfo(this, ref, msg);
        break;
      case MsgType.appInfo:
        await _onReceiveAppInfo(this, ref, msg);
        break;
      case MsgType.reqPairing:
        await _requestPairingDevice(this, msg);
        break;
      case MsgType.pairing:
        await _onDevicePairing(this, msg, address);
        break;
      case MsgType.paired:
        await _onDevicePaired(this, msg, address);
        break;
      case MsgType.cancelPairing:
        _onDevicePairingCanceled(this, msg);
        break;
      case MsgType.file:
        //todo
        // String ip = client.ip;
        // int port = msg.data['port'];
        // int size = msg.data['size'];
        // String fileName = msg.data['fileName'];
        // int fileId = msg.data['fileId'];
        // try {
        //   await FileSyncHandler.receiveFile(
        //     ip: ip,
        //     port: port,
        //     size: size,
        //     fileName: fileName,
        //     devId: msg.send.guid,
        //     userId: msg.userId,
        //     fileId: fileId,
        //     context: Get.context!,
        //   );
        // } catch (err, stack) {
        //   logger.debug(
        //     tag,
        //     'receive file failed. ip:$ip, port: $port, size: $size, fileName: $fileName. '
        //     '$err $stack',
        //   );
        // }
        break;
      default:
    }
  }

  /// 串行处理一个连接候选，避免旧会话和新候选同时登记。
  Future<bool> processCandidate(DeviceConnectionRequest request) async {
    SecureSocketClient? candidate;
    try {
      if (request.token.isCanceled) return false;
      final expectedDevId = request.expectedDevId;
      if (expectedDevId != null) {
        final online = await _probeCurrentSessionBeforeCandidate(expectedDevId, request.token, reason: 'probe before ${request.description}');
        if (online || request.token.isCanceled) return online;
      }
      candidate = await request.connect(request.token);
      if (request.token.isCanceled) {
        await candidate.close();
        return false;
      }
      return registerCandidate(candidate, expectedDevId: expectedDevId, token: request.token);
    } catch (error, stackTrace) {
      logger.debug(tag, 'Device connection candidate failed. key=${request.workerKey}, request=${request.description}, error=$error $stackTrace');
      await candidate?.close();
      return false;
    }
  }

  /// 探活现有会话，在线时保留旧连接。
  Future<bool> _probeCurrentSessionBeforeCandidate(String devId, CancelToken token, {required String reason}) async {
    final current = sessions.get(devId);
    if (current == null) return false;
    if (await current.socket.testOnline()) {
      logger.debug(tag, 'Skip new connection because current session is online. device=$devId');
      return true;
    }
    if (token.isCanceled) return false;
    await closeSession(devId, current.socket, reason: reason, autoReconnect: false);
    return false;
  }

  /// 登记握手完成的客户端，并替换已经失效的旧会话。
  Future<bool> registerCandidate(SecureSocketClient client, {String? expectedDevId, CancelToken? token}) async {
    if (token?.isCanceled ?? false) {
      await client.close();
      return false;
    }
    final dev = client.devInfo;
    if (dev.guid == _self.guid || (expectedDevId != null && expectedDevId != dev.guid)) {
      await client.close();
      return false;
    }
    while (true) {
      final current = sessions.get(dev.guid);
      if (current == null || identical(current.socket, client)) break;
      if (await current.socket.testOnline()) {
        _reconnectNotifier.cancelReconnect(dev.guid);
        await client.close();
        return true;
      }
      await closeSession(dev.guid, current.socket, reason: 'replace stale session with ready candidate', autoReconnect: false);
      if (token?.isCanceled ?? false) {
        await client.close();
        return false;
      }
    }
    sessions.put(DeviceSocketSession(dev: dev, socket: client, isPaired: client.isPaired, minVersion: client.minVersion, version: client.version));
    _reconnectNotifier.cancelReconnect(dev.guid);
    await onDeviceConnected(dev, client, client.minVersion, client.version);
    if (client.isPaired) {
      unawaited(requestMissingData());
      try {
        final rulesExecutor = ref.read(rulesExecutorProvider.future);
        //todo
        // unawaited(rulesExecutor.requestAppInfo(devId));
      } catch (error, stackTrace) {
        logger.debug(tag, 'Request app info after Socket connected failed: $error $stackTrace');
      }
    }
    return true;
  }

  /// 关闭当前会话并按需触发重连。
  Future<void> closeSession(String devId, SecureSocketClient client, {required String reason, bool autoReconnect = true, bool sendDisconnect = false}) async {
    final session = sessions.removeIfCurrent(devId, client);
    if (session == null) return;
    session.closing = true;
    _reconnectNotifier.cancelReconnect(devId);
    _deviceNotifier.clearPairingSource(devId, session.socket.isForwardMode ? TransportProtocol.server : TransportProtocol.direct, force: true);
    _deviceState.registry.removeDevice(devId);
    _deviceNotifier.emitLifecycleEvent(DeviceDisconnected(devId));
    if (sendDisconnect) {
      try {
        await client.send(
          MessageData(
            send: _localDeviceInfo.baseDeviceInfo,
            key: MsgType.disConnect,
            data: const <String, dynamic>{},
          ).toJson(),
        );
      } catch (error, stackTrace) {
        logger.debug(tag, 'Send disconnect before close failed. device=$devId, error=$error $stackTrace');
      }
    }
    await client.close();
    if (session.isPaired && autoReconnect && !_disposed) {
      _deviceConnectionNotifier.showDisconnected(devId, isPaired: true);
      unawaited(_reconnectNotifier.attemptReconnect(devId));
    }
    logger.debug(tag, 'Device Socket closed. device=$devId, reason=$reason');
  }

  /// 底层传输关闭时移除对应会话。
  void handleTransportClosed(SecureSocketClient client, {required String reason}) {
    final entry = sessions.findBySocket(client);
    if (entry != null) {
      unawaited(closeSession(entry.key, client, reason: reason));
    }
  }

  /// 完成配对状态写入并发布设备生命周期事件。
  Future<void> onDevicePaired(BaseDeviceInfo dev, bool result, String? address) async {
    logger.debug(tag, '${dev.name} paired，address：$address');
    sessions.get(dev.guid)?.isPaired = result;
    if (result) {
      final protocol = (address?.isInternalIPv4 ?? false) ? TransportProtocol.direct : TransportProtocol.server;
      final dbDev = await _deviceDao.getById(dev.guid);
      await _deviceNotifier.confirmPairingState(
        device:
            dbDev ??
            Device(
              guid: dev.guid,
              devName: dev.name,
              uid: 0,
              type: dev.type.value,
              internalAddress: (address?.isInternalIPv4 ?? false) ? address : null,
              address: address,
              isPaired: true,
            ),
        localIsPaired: true,
        remoteIsPaired: true,
        protocol: protocol,
        manual: true,
      );
    }
    _deviceNotifier.emitLifecycleEvent(
      DevicePaired(
        device: dev,
        result: result,
        address: address,
      ),
    );
  }

  /// 清理取消配对状态和系统通知。
  void onPairingCanceled(BaseDeviceInfo dev) {
    logger.debug(tag, '${dev.name} cancelPairing');
    if (_pairingNotifyId != null) {
      _notifyNotifier.cancel('dev-pairing-${dev.guid}', _pairingNotifyId!);
    }
    _pairing = false;
    _pairingNotifyId = null;
    _deviceNotifier.emitLifecycleEvent(DevicePairingCanceled(dev));
  }

  /// 忘记设备并同步本地配对状态。
  Future<void> forgetDevice(BaseDeviceInfo dev, {bool updatePairingState = true}) async {
    logger.debug(tag, '${dev.name} forget');
    sessions.get(dev.guid)?.isPaired = false;
    final session = sessions.get(dev.guid);
    if (updatePairingState) {
      final dbDev = await _deviceDao.getById(dev.guid);
      await _deviceNotifier.confirmPairingState(
        device:
            dbDev ??
            Device(
              guid: dev.guid,
              devName: dev.name,
              uid: 0,
              type: dev.type.value,
              isPaired: false,
            ),
        localIsPaired: false,
        remoteIsPaired: false,
        protocol: session?.socket.isForwardMode ?? false ? .server : .direct,
        manual: true,
      );
    }
    _deviceNotifier.emitLifecycleEvent(DeviceForgotten(dev));
  }

  /// 取消当前配对弹窗
  void cancelPairing(BaseDeviceInfo dev) {
    if (!_pairing) return;
    _deviceParingCodeNotifier.removeCode(dev.guid);
    navigatorKey.currentContext?.pop();
    sendData(dev, .cancelPairing, {}, false);
    if (_pairingNotifyId != null) {
      _notifyNotifier.cancel('dev-pairing-${dev.guid}', _pairingNotifyId!);
    }
    _pairing = false;
    _pairingNotifyId = null;
  }

  /// 记录连接成功后的地址、在线状态和设备生命周期事件。
  Future<void> onDeviceConnected(BaseDeviceInfo dev, SecureSocketClient client, AppVersion minVersion, AppVersion version) async {
    _deviceConnectionNotifier.showConnected(dev.guid, isPaired: sessions.get(dev.guid)?.isPaired ?? false);
    final port = client.isForwardMode ? _forwardServer.forwardServerPort : client.port;
    final address = '${client.ip}:$port';
    if (address.isInternalIPv4) {
      await _deviceDao.updateDeviceInternalAddress(dev.guid, address);
    }
    await _deviceDao.updateDeviceAddress(dev.guid, address);
    _deviceState.registry.addDevice(dev, client.isForwardMode ? .server : .direct, version, minVersion);
    _deviceNotifier.emitLifecycleEvent(
      DeviceConnected(
        device: dev,
        minVersion: minVersion,
        version: version,
        protocol: client.isForwardMode ? .server : .direct,
      ),
    );
  }

  /// 向当前会话发送消息；发送失败时交给直连层关闭底层传输。
  /// 会话已被移除或尚未登记时抛出 [DeviceNotConnectedException]。
  @override
  Future<void> sendData(BaseDeviceInfo device, MsgType key, Map<String, dynamic> data, [bool onlyPaired = true]) async {
    final self = _localDeviceInfo.baseDeviceInfo;
    final session = sessions.get(device.guid);
    if (session == null) {
      throw DeviceNotConnectedException(device.guid);
    }
    final msg = MessageData(
      send: self,
      key: key,
      data: data,
      recv: null,
    );
    await session.socket.send(msg.toJson());
  }
}
