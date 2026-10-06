import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:clipshare/core/constants/network_constants.dart' as net;
import 'package:clipshare/core/constants/app_constants.dart';
import 'package:clipshare/core/constants/platform_constants.dart';
import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/database/dao/config_dao.dart';
import 'package:clipshare/core/runtime/app_state/app_state_provider.dart';
import 'package:clipshare/core/services/device/device_provider.dart';
import 'package:clipshare/core/services/device/local_device_info.dart';
import 'package:clipshare/core/services/device/local_device_info_provider.dart';
import 'package:clipshare/core/services/transport/events/forward_status_event_provider.dart';
import 'package:clipshare/core/services/transport/socket/direct/direct_provider.dart';
import 'package:clipshare/core/services/transport/socket/discovery/discovery_provider.dart';
import 'package:clipshare/core/services/transport/socket/session/session_provider.dart';
import 'package:clipshare/core/settings/discovery/discovery_settings.dart';
import 'package:clipshare/core/settings/discovery/discovery_settings_provider.dart';
import 'package:clipshare/core/settings/forward/forward_server_status.dart';
import 'package:clipshare/core/settings/forward/forward_settings.dart';
import 'package:clipshare/core/settings/forward/forward_settings_provider.dart';
import 'package:clipshare/core/settings/forward/forward_way.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/extensions/number_extension.dart';
import 'package:clipshare/shared/extensions/string_extension.dart';
import 'package:clipshare/shared/utils/dialog.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:clipshare/shared/utils/parallerl_task.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../client/socket/forward_socket_client.dart';
import '../../client/socket/secure_socket_client.dart';
import '../../enums/connection_mode.dart';
import '../session/device_connection_queue.dart';
import '../../enums/forward_msg_type.dart';
import '../../models/local_socket_base_info.dart';
import '../../models/message_data.dart';
import '../session/reconnect_provider.dart';

part 'forward_message_handler.dart';

part 'forward_server_provider.g.dart';

/// 中转控制连接和中转设备发现
@Riverpod(keepAlive: true)
class ForwardServerNotifier extends _$ForwardServerNotifier {
  static const tag = 'ForwardServerNotifier';
  static const maxParallelCnt = 10;
  ForwardSocketClient? _forwardClient;
  Future<void>? _forwardConnectFuture;
  Timer? _forwardReconnectTimer;
  CancelTokenSource? _forwardConnectTokenSource;
  Timer? _forwardClientHeartbeatTimer;
  DateTime? _lastForwardServerPingTime;
  bool _autoConnForwardServer = true;
  bool _disposed = false;

  bool get connected => _forwardClient != null;

  SessionNotifier get _sessionNotifier => ref.read(sessionProvider.notifier);
  DiscoveryNotifier get _discoveryNotifier => ref.read(discoveryProvider.notifier);

  DiscoverySettings get _discoverySettings => ref.read(discoverySettingsProvider).requireValue;
  ForwardSettings get _forwardSettings => ref.read(forwardSettingsProvider).requireValue;

  LocalDeviceInfo get _localDeviceInfo => ref.read(localDeviceInfoProvider).requireValue;

  BaseDeviceInfo get _self => _localDeviceInfo.baseDeviceInfo;

  AppStateNotifier get _appStateNotifier => ref.read(appStateProvider.notifier);

  ConfigDao get _configDao => ref.read(appDbProvider).requireValue.configDao;

  bool get _isForwardServerEnabled {
    return _forwardSettings.enable && _forwardSettings.way == ForwardWay.server;
  }

  String? get forwardServerHost {
    if (!_isForwardServerEnabled) return null;
    return _forwardSettings.serverConfig?.host;
  }

  int? get forwardServerPort {
    if (!_isForwardServerEnabled) return null;
    return _forwardSettings.serverConfig?.port.toInt();
  }

  bool get _serverValid {
    return forwardServerHost != null && forwardServerPort != null;
  }

  Map<String, dynamic> get forwardClientBaseMsg => {
    'self': _self.guid,
    'devName': _localDeviceInfo.localName,
    'platform': defaultTargetPlatform.name.upperFirst,
    'appVersion': _localDeviceInfo.appVersion.toString(),
  };

  @override
  bool build() {
    ref.onDispose(() {
      _disposed = true;
      _forwardConnectTokenSource?.cancel();
      _forwardReconnectTimer?.cancel();
      _stopJudgeForwardClientAlive();
      unawaited(disconnectForwardServer());
    });
    return false;
  }

  /// 根据已保存设备生成中转连接候选
  Future<List<Future<void> Function()>> _forwardDiscovering() async {
    if (_forwardClient == null) return [];
    final devices = await ref.read(appDbProvider).requireValue.deviceDao.getAllDevices();
    return [for (final device in devices) () => connectDevice(device.guid)];
  }

  /// 监测中转控制通道是否持续收到服务端心跳
  void _startJudgeForwardClientAlivePeriod() {
    _stopJudgeForwardClientAlive();
    _forwardClientHeartbeatTimer = Timer.periodic(const Duration(seconds: 35), (_) {
      final ping = _lastForwardServerPingTime;
      final client = _forwardClient;
      if (client == null || ping == null || DateTime.now().difference(ping).inSeconds < 35) return;
      _handleForwardClientDisconnected(client, 'forward control heartbeat timeout', closeClient: true);
    });
  }

  /// 停止中转控制通道心跳监测
  void _stopJudgeForwardClientAlive() {
    _forwardClientHeartbeatTimer?.cancel();
    _forwardClientHeartbeatTimer = null;
  }

  /// 停止中转控制通道检测
  void stopHeartbeatWatch() => _stopJudgeForwardClientAlive();

  /// 连接中转服务
  Future<void> connectForwardServer([bool startDiscovery = false]) async {
    if (_disposed) {
      return;
    }
    if (!_isForwardServerEnabled) {
      return;
    }
    if (!_serverValid) {
      return Future.value();
    }
    if (_forwardClient != null) {
      if (startDiscovery) {
        unawaited(_runForwardDiscoveryOnce());
      }
      final enableAutoSyncOnScreenOpened = _discoverySettings.enableAutoSyncOnScreenOpened;
      unawaited(_discoveryNotifier.startDiscoveryDevices(scan: enableAutoSyncOnScreenOpened));
      return Future.value();
    }
    final running = _forwardConnectFuture;
    if (running != null) {
      return running;
    }
    _autoConnForwardServer = true;
    _forwardReconnectTimer?.cancel();
    _forwardReconnectTimer = null;
    final tokenSource = CancelTokenSource();
    _forwardConnectTokenSource = tokenSource;
    late final Future<void> task;
    task = _connectForwardServerOnce(tokenSource, startDiscovery).whenComplete(() {
      if (identical(_forwardConnectFuture, task)) {
        _forwardConnectFuture = null;
      }
      if (identical(_forwardConnectTokenSource, tokenSource)) {
        _forwardConnectTokenSource = null;
      }
    });
    _forwardConnectFuture = task;
    return task;
  }

  /// 在中转控制连接已存在时单独触发一次中转设备发现。
  Future<void> _runForwardDiscoveryOnce() async {
    final list = await _forwardDiscovering();
    await ParallelTask(tasks: list, maxParallelCnt: maxParallelCnt).run();
  }

  /// 执行一次中转控制连接，并在成功后发送基础注册信息。
  Future<void> _connectForwardServerOnce(CancelTokenSource tokenSource, bool startDiscovery) async {
    _updateForwardStatus(ForwardServerStatus.connecting);
    try {
      final client = await ForwardSocketClient.connect(
        ip: forwardServerHost!,
        port: forwardServerPort!,
        onMessage: (self, data) {
          if (!identical(_forwardClient, self)) {
            return;
          }
          final json = jsonDecode(data) as Map<String, dynamic>;
          unawaited(_onForwardServerReceived(json));
        },
        onDone: (self) => _onForwardClientClosed(self, 'forward control done'),
        onError: (error, self) => _onForwardClientClosed(self, 'forward control error: $error'),
        cancelToken: tokenSource.token,
      );
      if (tokenSource.token.isCanceled || _disposed || !_autoConnForwardServer) {
        await client.close();
        return;
      }
      _forwardClient = client;
      _lastForwardServerPingTime = DateTime.now();
      logger.debug(tag, 'Forward control connected.');
      _updateForwardStatus(ForwardServerStatus.connected);
      _startJudgeForwardClientAlivePeriod();
      final connData = forwardClientBaseMsg
        ..addAll({
          'connType': ForwardConnType.base.name,
        });
      final key = _forwardSettings.serverConfig?.key;
      if (key != null) {
        connData['key'] = key;
      }
      client.send(connData);
      client.send({
        'type': ForwardMsgType.version.name,
      });
      if (startDiscovery) {
        Future.delayed(net.forwardReconnectDelay, () async {
          if (!identical(_forwardClient, client)) {
            return;
          }
          final list = await _forwardDiscovering();
          await ParallelTask(tasks: list, maxParallelCnt: maxParallelCnt).run();
        });
      }
    } catch (error, stackTrace) {
      if (tokenSource.token.isCanceled || !_autoConnForwardServer || _disposed) {
        return;
      }
      _updateForwardStatus(ForwardServerStatus.disconnected);
      logger.debug(tag, 'Forward control connect failed: $error $stackTrace');
      _scheduleForwardReconnect(startDiscovery);
    }
  }

  /// 中转控制连接断开只由当前 client 触发，旧回调不能重新拉起连接。
  void _onForwardClientClosed(ForwardSocketClient client, String reason) {
    _handleForwardClientDisconnected(client, reason);
  }

  /// 统一处理中转控制连接的被动断线，确保心跳超时也会同步状态并调度重连。
  void _handleForwardClientDisconnected(
    ForwardSocketClient client,
    String reason, {
    bool closeClient = false,
  }) {
    if (!identical(_forwardClient, client)) {
      return;
    }
    logger.debug(tag, 'Forward control closed. reason=$reason');
    _forwardClient = null;
    _stopJudgeForwardClientAlive();
    _updateForwardStatus(ForwardServerStatus.disconnected);
    if (closeClient) {
      unawaited(client.close());
    }
    unawaited(_disconnectForwardSockets());
    if (_autoConnForwardServer && !_disposed) {
      _scheduleForwardReconnect(true);
    }
  }

  /// 保证中转控制连接最多只有一个延迟重连 timer。
  void _scheduleForwardReconnect([bool startDiscovery = true]) {
    if (_forwardReconnectTimer?.isActive ?? false) {
      return;
    }
    _forwardReconnectTimer = Timer(net.forwardReconnectDelay, () {
      _forwardReconnectTimer = null;
      if (_autoConnForwardServer && !_disposed) {
        unawaited(connectForwardServer(startDiscovery));
      }
    });
  }

  ///断开中转服务器
  Future<void> disConnectForwardServer() async {
    logger.debug(tag, 'disConnectForwardServer');
    _autoConnForwardServer = false;
    _forwardReconnectTimer?.cancel();
    _forwardReconnectTimer = null;
    _forwardConnectTokenSource = null;
    _stopJudgeForwardClientAlive();
    final client = _forwardClient;
    _forwardClient = null;
    if (client != null) {
      await client.close();
      _updateForwardStatus(ForwardServerStatus.disconnected);
    }
    await _disconnectForwardSockets();
  }

  //region Update server status
  /// server 中转继续只发三态，但和存储中转共用同一套状态通知入口。
  void _updateForwardStatus(ForwardServerStatus status) {
    final eventNotifier = ref.read(forwardStatusEventProvider.notifier);
    eventNotifier.emit(status);
  }

  //endregion

  ///断开所有通过中转服务器的连接
  Future<void> _disconnectForwardSockets() => _sessionNotifier.closeForwardSessions();

  ///中转 监听消息处理
  Future<void> _onForwardServerReceived(Map<String, dynamic> data) async {
    final type = ForwardMsgType.getValue(data['type']);
    final context = navigatorKey.currentContext!;
    switch (type) {
      case ForwardMsgType.ping:
        _onForwardPing(this);
        break;
      case ForwardMsgType.fileSyncNotAllowed:
        await _onForwardFileSyncNotAllowed(context);
        break;
      case ForwardMsgType.check:
        await _onForwardCheck(this, context, data);
        break;
      case ForwardMsgType.requestConnect:
        _onForwardRequestConnect(this, data);
        break;
      case ForwardMsgType.version:
        _onForwardVersion(this, data);
        break;
      case ForwardMsgType.sendFile:
        await _onForwardRequestSendFile(this, context, data);
        break;
      case ForwardMsgType.fileReceiverConnected:
        _onForwardFileReceiverConnected(this, data);
        break;
      default:
    }
  }

  /// 通过中转服务器建立设备连接候选。
  Future<bool> connectDevice(String devId, {CancelToken? cancelToken}) async {
    if (!_serverValid || !_isForwardServerEnabled) {
      return false;
    }
    final localSource = CancelTokenSource();
    final token = cancelToken == null ? localSource.token : localSource.token.combine(cancelToken);
    final direct = ref.read(directProvider.notifier);
    final request = DeviceConnectionRequest(
      workerKey: devId,
      expectedDevId: devId,
      description: 'manual forward connect',
      token: token,
      connect: (requestToken) => SecureSocketClient.connect(
        ip: forwardServerHost!,
        port: forwardServerPort!,
        localBaseInfo: direct.localBaseInfo,
        loadDevice: direct.loadDevice,
        targetDevId: devId,
        selfDevId: _self.guid,
        connectionMode: ConnectionMode.forward,
        onMessage: (client, json) => unawaited(_sessionNotifier.onSocketReceived(client, MessageData.fromJson(json))),
        onDone: (client) => _sessionNotifier.handleTransportClosed(client, reason: 'forward device done'),
        onError: (error, client) => _sessionNotifier.handleTransportClosed(client, reason: 'forward device error: $error'),
        cancelToken: requestToken,
      ),
    );
    return _sessionNotifier.submitCandidate(request);
  }

  /// 兼容已有调用方的明确命名入口。
  Future<bool> manualConnectByForward(String devId, {CancelToken? cancelToken}) => connectDevice(devId, cancelToken: cancelToken);

  /// 断开中转控制连接及其设备会话。
  Future<void> disconnectForwardServer() => disConnectForwardServer();

  void _invalidate(ProviderOrFamily providerOrFamily) => ref.invalidate(providerOrFamily);
}
