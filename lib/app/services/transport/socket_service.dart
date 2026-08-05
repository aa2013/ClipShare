import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:clipshare/app/data/enums/forward_way.dart';
import 'package:clipshare/app/data/enums/connection_mode.dart';
import 'package:clipshare/app/data/enums/forward_server_status.dart';
import 'package:clipshare/app/data/enums/forward_msg_type.dart';
import 'package:clipshare/app/data/enums/module.dart';
import 'package:clipshare/app/data/enums/msg_type.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/enums/transport_protocol.dart';
import 'package:clipshare/app/data/models/dev_info.dart';
import 'package:clipshare/app/data/models/message_data.dart';
import 'package:clipshare/app/data/models/version.dart';
import 'package:clipshare/app/data/repository/entity/tables/app_info.dart';
import 'package:clipshare/app/data/repository/entity/tables/device.dart';
import 'package:clipshare/app/handlers/dev_pairing_handler.dart';
import 'package:clipshare/app/handlers/socket/forward_socket_client.dart';
import 'package:clipshare/app/handlers/socket/secure_socket_client.dart';
import 'package:clipshare/app/handlers/socket/secure_socket_server.dart';
import 'package:clipshare/app/handlers/sync/abstract_data_sender.dart';
import 'package:clipshare/app/handlers/sync/ack_sync_sender.dart';
import 'package:clipshare/app/handlers/sync/file_sync_handler.dart';
import 'package:clipshare/app/handlers/sync/missing_data_sync_handler.dart';
import 'package:clipshare/app/modules/rules_module/rules_controller.dart';
import 'package:clipshare/app/services/device_connection_notify_service.dart';
import 'package:clipshare/app/services/device_service.dart';
import 'package:clipshare/app/services/history_sync_progress_service.dart';
import 'package:clipshare/app/utils/notify_util.dart';
import 'package:clipshare/app/utils/parallerl_task.dart';
import 'package:clipshare/app/listeners/dev_alive_listener.dart';
import 'package:clipshare/app/listeners/discover_listener.dart';
import 'package:clipshare/app/listeners/forward_status_listener.dart';
import 'package:clipshare/app/listeners/screen_opened_listener.dart';
import 'package:clipshare/app/services/clipboard_source_service.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/services/transport/connection_registry_service.dart';
import 'package:clipshare/app/services/transport/device_connection_queue.dart';
import 'package:clipshare/app/services/transport/device_socket_session_store.dart';
import 'package:clipshare/app/services/transport/transport_heartbeat_service.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/crypto.dart';
import 'package:clipshare/app/utils/extensions/device_extension.dart';
import 'package:clipshare/app/utils/extensions/number_extension.dart';
import 'package:clipshare/app/utils/extensions/platform_extension.dart';
import 'package:clipshare/app/utils/extensions/string_extension.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:clipshare/app/utils/network_util.dart';
import 'package:collection/collection.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SocketService extends GetxService with ScreenOpenedObserver, DataSender {
  final appConfig = Get.find<ConfigService>();
  final connRegService = Get.find<ConnectionRegistryService>();
  final dbService = Get.find<DbService>();
  final devConnNotifyService = Get.find<DeviceConnectionNotifyService>();
  final devService = Get.find<DeviceService>();
  final transportHeartbeatService = Get.find<TransportHeartbeatService>();
  static const String tag = "SocketService";
  static const maxParallelCnt = 10;
  static const _socketHeartbeatTaskName = 'socket-ping';

  /// 设备连接 worker 空闲后的保留时间，避免刚销毁又入队导致请求无人消费。
  static const _connectionWorkerIdleTtl = Duration(seconds: 15);

  /// 自动重连进入中转候选前的最大错峰时间，降低双端同时打中转导致的握手碰撞。
  static const _forwardReconnectMaxSkew = Duration(milliseconds: 1200);

  /// 中转控制连接心跳计时器，只判断 server 控制通道是否仍有服务端 ping。
  Timer? _forwardClientHeartbeatTimer;

  /// 最近一次收到中转服务器 ping 的时间，用于识别控制通道半开。
  DateTime? _lastForwardServerPingTime;

  /// 当前在线设备会话表，所有写入和删除都通过 devId 与 client identity 校验。
  final DeviceSocketSessionStore _sessions = DeviceSocketSessionStore();

  /// 全局连接入口，内部按设备创建 await-for worker 来串行处理候选连接。
  late final DeviceConnectionQueue _connectionQueue;

  /// 每个设备当前重连循环的取消源，新重连会取消旧 token。
  final Map<String, CancelTokenSource> _reconnectTokenSources = {};

  /// 每个设备正在运行的重连 Future，避免同设备重复启动重连循环。
  final Map<String, Future<void>> _reconnectTasks = {};

  /// 按地址去重的连接请求，避免同一个 IP/中转目标被并发提交多次。
  final Map<String, Future<bool>> _inFlightConnectionRequests = {};

  /// 按设备去重的广播连接请求，广播多次到达时只保留当前候选。
  final Map<String, Future<void>> _broadcastConnectionRequests = {};

  /// Socket 监听服务端，入站 client ready 后才进入业务层。
  late SecureSocketServer _server;

  /// 中转控制通道，不承载设备业务数据，只负责 server 协调消息。
  ForwardSocketClient? _forwardClient;

  /// 当前中转控制连接 Future，保证 single-flight。
  Future<void>? _forwardConnectFuture;

  /// 中转控制连接断开后的延迟重连 timer。
  Timer? _forwardReconnectTimer;

  /// 当前中转控制连接的取消源，主动断开时用于取消未完成连接。
  CancelTokenSource? _forwardConnectTokenSource;

  /// 服务释放标记，所有异步回调必须检查它再决定是否重连。
  bool _disposed = false;

  bool get forwardServerConnected => _forwardClient != null;

  /// 配对流程临时记录的候选地址，用于配对成功后写入正确连接地址。
  final Set<String> _pendingPairingAddresses = {};

  /// 中转文件发送记录，server 通知接收端 ready 时按 fileId 找回 handler。
  final Map<int, FileSyncHandler> _forwardFiles = {};

  /// 当前是否存在配对弹窗，避免重复弹出多个验证码窗口。
  bool _pairing = false;

  /// 当前配对通知 id，取消配对或完成后用于关闭系统通知。
  int? _pairingNotifyId;

  /// SocketService 是全局服务，防止重复 init。
  static bool _isInit = false;

  /// 屏幕是否处于打开状态，由统一心跳服务决定息屏后是否自动断连。
  bool screenOpened = true;

  /// 是否允许中转控制通道自动重连，主动断开后必须关闭。
  bool _autoConnForwardServer = true;

  /// 当前发现流程的取消源，停止发现只影响未登记候选和后续任务。
  CancelTokenSource _discoveryTokenSource = CancelTokenSource();

  String? get forwardServerHost {
    if (!appConfig.enableForward || appConfig.forwardWay != ForwardWay.server) return null;
    return appConfig.forwardServer!.host;
  }

  int? get forwardServerPort {
    if (!appConfig.enableForward || appConfig.forwardWay != ForwardWay.server) return null;
    return appConfig.forwardServer!.port.toInt();
  }

  /// 当前绑定的组播监听 Socket，重启发现时会先关闭再重新绑定。
  List<RawDatagramSocket> _multicastSockets = [];

  //region dev registry
  final DeviceConnectionRegistry _registry;

  List<DevAliveListener> get _devAliveListeners => _registry.devAliveListeners;

  List<DiscoverListener> get _discoverListeners => _registry.discoverListeners;

  List<ForwardStatusListener> get _forwardStatusListener => _registry.forwardStatusListener;

  //endregion

  SocketService(this._registry) {
    _connectionQueue = DeviceConnectionQueue(
      processor: _processDeviceConnectionRequest,
      idleTtl: _connectionWorkerIdleTtl,
    );
  }

  Future<SocketService> init() async {
    if (_isInit) throw Exception("已初始化");
    // 初始化 Socket 监听后注册统一心跳任务，避免各传输服务各自维护定时器。
    await _runSocketServer();
    _registerSocketHeartbeatTask();
    // 连接中转服务器。
    await connectForwardServer();
    startDiscoveryDevices();
    startHeartbeatTest();
    ScreenOpenedListener.inst.register(this);
    _isInit = true;
    return this;
  }

  @override
  void onClose() {
    _disposed = true;
    _discoveryTokenSource.cancel();
    for (final tokenSource in _reconnectTokenSources.values) {
      tokenSource.cancel();
    }
    _reconnectTokenSources.clear();
    _forwardConnectTokenSource?.cancel();
    _forwardReconnectTimer?.cancel();
    unawaited(_connectionQueue.close());
    ScreenOpenedListener.inst.remove(this);
    transportHeartbeatService.unregisterTask(_socketHeartbeatTaskName);
    unawaited(disConnectForwardServer());
    unawaited(_server.close());
    _isInit = false;
    super.onClose();
  }

  ///判断设备是否在线
  bool isOnline(String devId, bool requiredPaired) {
    return _sessions.isOnline(devId, requiredPaired: requiredPaired);
  }

  /// 将连接候选提交给全局队列；同设备 worker 会保证请求串行完成。
  Future<bool> _enqueueDeviceConnection(DeviceConnectionRequest request) {
    return _connectionQueue.enqueue(request);
  }

  /// 处理单个连接候选；已知 devId 时必须先探活当前 session，活着就跳过新连接。
  Future<bool> _processDeviceConnectionRequest(DeviceConnectionRequest request) async {
    SecureSocketClient? candidate;
    try {
      if (request.token.isCanceled) {
        return false;
      }
      final expectedDevId = request.expectedDevId;
      if (expectedDevId != null) {
        final currentIsOnline = await _probeCurrentSessionBeforeCandidate(
          expectedDevId,
          request.token,
          reason: 'probe before ${request.description}',
        );
        if (currentIsOnline || request.token.isCanceled) {
          return currentIsOnline;
        }
      }

      // 只有没有可用旧连接，或旧连接强制探活失败后，才允许创建候选 Socket。
      candidate = await request.connect(request.token);
      if (request.token.isCanceled) {
        await candidate.close();
        return false;
      }
      return await _registerReadyClient(
        candidate,
        expectedDevId: expectedDevId,
        token: request.token,
      );
    } catch (error, stackTrace) {
      logger.debug(tag, 'Device connection candidate failed. key=${request.workerKey}, request=${request.description}, error=$error $stackTrace');
      await candidate?.close();
      return false;
    }
  }

  /// 对已有当前 session 做唯一允许的预检：testOnline，在线则保留旧连接并跳过候选。
  Future<bool> _probeCurrentSessionBeforeCandidate(
    String devId,
    CancelToken token, {
    required String reason,
  }) async {
    final current = _findSessionByExpectedDevId(devId);
    if (current == null) {
      return false;
    }
    final currentDevId = current.dev.guid;
    final online = await current.socket.testOnline();
    if (online) {
      logger.debug(tag, 'Skip new connection because current session is online. device=$currentDevId');
      return true;
    }
    if (token.isCanceled) {
      return false;
    }
    await _closeCurrentSession(
      currentDevId,
      current.socket,
      reason: reason,
      autoReconnect: false,
    );
    return false;
  }

  /// 按期望设备 id 查找当前 session；设备 id 必须完全一致，debug/release 前缀不能互相兼容。
  DeviceSocketSession? _findSessionByExpectedDevId(String expectedDevId) {
    return _sessions.get(expectedDevId);
  }

  /// 唯一登记 ready client 的入口；未知候选握手拿到 devId 后也必须在这里二次探活。
  Future<bool> _registerReadyClient(
    SecureSocketClient client, {
    String? expectedDevId,
    CancelToken? token,
  }) async {
    if (token?.isCanceled ?? false) {
      await client.close();
      return false;
    }
    final dev = client.devInfo;
    final devId = dev.guid;
    if (devId == appConfig.device.guid) {
      await client.close();
      return false;
    }
    if (expectedDevId != null && expectedDevId != devId) {
      logger.warn(tag, 'Ready client target mismatch. expected=$expectedDevId, actual=$devId');
      await client.close();
      return false;
    }

    // 登记前循环探活当前 session，处理候选握手期间已有新连接登记成功的竞态。
    while (true) {
      final current = _sessions.get(devId);
      if (current == null || identical(current.socket, client)) {
        break;
      }
      final online = await current.socket.testOnline();
      if (online) {
        _cancelReconnect(devId);
        await client.close();
        return true;
      }
      await _closeCurrentSession(
        devId,
        current.socket,
        reason: 'replace stale session with ready candidate',
        autoReconnect: false,
      );
      if (token?.isCanceled ?? false) {
        await client.close();
        return false;
      }
    }

    final session = DeviceSocketSession(
      dev: dev,
      socket: client,
      isPaired: client.isPaired,
      minVersion: client.minVersion,
      version: client.version,
    );
    _sessions.put(session);
    _cancelReconnect(devId);
    await _onDevConnected(dev, client, client.minVersion, client.version);
    if (client.isPaired) {
      unawaited(reqMissingData());
      try {
        final ruleController = Get.find<RulesController>();
        unawaited(ruleController.requestAppInfo(devId));
      } catch (error, stackTrace) {
        logger.debug(tag, 'Request app info after Socket connected failed: $error $stackTrace');
      }
    }
    return true;
  }

  Future<void> _closeCurrentSession(
    String devId,
    SecureSocketClient client, {
    required String reason,
    bool autoReconnect = true,
    bool sendDisconnect = false,
  }) async {
    final session = _sessions.removeIfCurrent(devId, client);
    if (session == null) {
      return;
    }
    session.closing = true;
    _cancelReconnect(devId);
    devService.clearPairingSource(
      devId,
      session.socket.isForwardMode ? TransportProtocol.server : TransportProtocol.direct,
    );
    _registry.removeDevice(devId);
    for (var listener in _devAliveListeners) {
      try {
        listener.onDisconnected(devId);
      } catch (error, stackTrace) {
        logger.debug(tag, '$error $stackTrace');
      }
    }
    if (sendDisconnect) {
      try {
        await client.send(
          MessageData(
            userId: appConfig.userId,
            send: appConfig.devInfo,
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
      devConnNotifyService.showDisconnected(devId, isPaired: true);
      unawaited(_attemptReconnect(devId));
    }
    logger.debug(tag, 'Device Socket closed. device=$devId, reason=$reason');
  }

  void _onClientTransportClosed(SecureSocketClient client, {required String reason}) {
    final entry = _sessions.findBySocket(client);
    if (entry != null) {
      unawaited(_closeCurrentSession(entry.key, client, reason: reason));
    }
  }

  ///监听广播
  Future<void> _startListenMulticast() async {
    _closeMulticastSockets();
    _multicastSockets = await _getSockets(Constants.multicastGroup, appConfig.port);
    for (var multicast in _multicastSockets) {
      multicast.listen((event) {
        final datagram = multicast.receive();
        if (datagram == null) {
          return;
        }
        var data = CryptoUtil.base64DecodeStr(utf8.decode(datagram.data));
        Map<String, dynamic> json = jsonDecode(data);
        var msg = MessageData.fromJson(json);
        var dev = msg.send;
        //是本机跳过
        if (dev.guid == appConfig.devInfo.guid) {
          return;
        }
        switch (msg.key) {
          case MsgType.broadcastInfo:
            _runSingleBroadcastCandidate(msg, datagram);
            break;
          default:
        }
      });
    }
  }

  /// 广播可能短时间重复到达，同一设备只保留一个正在处理的候选请求。
  void _runSingleBroadcastCandidate(MessageData msg, Datagram datagram) {
    final devId = msg.send.guid;
    final running = _broadcastConnectionRequests[devId];
    if (running != null) {
      return;
    }
    late final Future<void> future;
    future = _onBroadcastInfoReceived(msg, datagram).whenComplete(() {
      if (identical(_broadcastConnectionRequests[devId], future)) {
        _broadcastConnectionRequests.remove(devId);
      }
    });
    _broadcastConnectionRequests[devId] = future;
  }

  /// 关闭当前所有组播监听 Socket；发现停止或重启时必须释放端口绑定。
  void _closeMulticastSockets() {
    for (final socket in _multicastSockets) {
      socket.close();
    }
    _multicastSockets = [];
  }

  /// 处理广播发现到的设备候选，真正连接交给设备级 mailbox 串行执行。
  Future<void> _onBroadcastInfoReceived(
    MessageData msg,
    Datagram datagram,
  ) async {
    DevInfo dev = msg.send;
    var device = await dbService.deviceDao.getById(dev.guid, appConfig.userId);
    var isPaired = device != null && device.isPaired;
    //未配对且不允许被发现，结束
    if (!appConfig.allowDiscover && !isPaired) {
      return;
    }
    //建立连接
    String ip = datagram.address.address;
    var port = msg.data["port"];
    logger.debug(tag, "${dev.name} ip: $ip，port $port");
    _pendingPairingAddresses.add("$ip:$port");
    await _connectFromBroadcast(dev, ip, msg.data["port"]);
  }

  /// 将广播候选提交到设备 mailbox，避免同一设备的广播/直连/中转候选互相抢占状态。
  Future<bool> _connectFromBroadcast(DevInfo dev, String ip, int port) {
    final token = _discoveryTokenSource.token;
    final request = DeviceConnectionRequest(
      workerKey: dev.guid,
      expectedDevId: dev.guid,
      description: 'broadcast direct connect $ip:$port',
      token: token,
      connect: (token) {
        return SecureSocketClient.connect(
          ip: ip,
          port: port,
          prime1: appConfig.prime1,
          prime2: appConfig.prime2,
          dhAesKey: appConfig.dhAesKey,
          onMessage: (client, json) {
            final msg = MessageData.fromJson(json);
            unawaited(_onSocketReceived(client, msg));
          },
          onDone: (client) => _onClientTransportClosed(client, reason: 'broadcast direct done'),
          onError: (error, client) => _onClientTransportClosed(client, reason: 'broadcast direct error: $error'),
          cancelToken: token,
        );
      },
    );
    return _enqueueDeviceConnection(request);
  }

  /// 运行服务端 Socket；入站连接必须在 SecureSocketClient 内完成设备握手后才进入业务层。
  Future<void> _runSocketServer() async {
    _server = await SecureSocketServer.bind(
      ip: '0.0.0.0',
      port: appConfig.port,
      onConnected: (ip, port) {
        logger.debug(
          tag,
          "新连接来自 ip:$ip port:$port",
        );
      },
      onClientReady: (client) {
        unawaited(_registerReadyClient(client));
      },
      onMessage: (client, json) {
        final msg = MessageData.fromJson(json);
        unawaited(_onSocketReceived(client, msg));
      },
      onError: (err) {
        logger.error(tag, "Socket server error: $err");
      },
      onClientError: (e, ip, port, client) {
        _onClientTransportClosed(client, reason: "server client error: $e");
      },
      onClientDone: (ip, port, client) {
        _onClientTransportClosed(client, reason: "server client done");
      },
      onDone: () {
        logger.debug(tag, "Socket server closed");
        for (final session in _sessions.snapshot()) {
          if (!session.socket.isForwardMode) {
            unawaited(_closeCurrentSession(session.dev.guid, session.socket, reason: "server closed"));
          }
        }
      },
    );
  }

  /// 连接中转控制通道；同一时刻只允许一个连接 Future 和一个延迟重试 timer。
  Future<void> connectForwardServer([bool startDiscovery = false]) async {
    if (_disposed) {
      return;
    }
    if (!appConfig.enableForward || appConfig.forwardWay != ForwardWay.server) {
      return;
    }
    if (forwardServerHost == null || forwardServerPort == null) {
      return Future.value();
    }
    if (_forwardClient != null) {
      if (startDiscovery) {
        unawaited(_runForwardDiscoveryOnce());
      }
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
      logger.debug(tag, "Forward control connected.");
      _updateForwardStatus(ForwardServerStatus.connected);
      _startJudgeForwardClientAlivePeriod();
      final connData = ForwardSocketClient.baseMsg
        ..addAll({
          "connType": ForwardConnType.base.name,
        });
      final key = appConfig.forwardServer?.key;
      if (key != null) {
        connData["key"] = key;
      }
      client.send(connData);
      client.send({
        "type": ForwardMsgType.version.name,
      });
      if (startDiscovery) {
        Future.delayed(Constants.forwardReconnectDelay, () async {
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
      logger.debug(tag, "Forward control connect failed: $error $stackTrace");
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
    logger.debug(tag, "Forward control closed. reason=$reason");
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
    _forwardReconnectTimer = Timer(Constants.forwardReconnectDelay, () {
      _forwardReconnectTimer = null;
      if (_autoConnForwardServer && !_disposed) {
        unawaited(connectForwardServer(startDiscovery));
      }
    });
  }

  ///断开中转服务器
  Future<void> disConnectForwardServer() async {
    logger.debug(tag, "disConnectForwardServer");
    _autoConnForwardServer = false;
    _forwardReconnectTimer?.cancel();
    _forwardReconnectTimer = null;
    _forwardConnectTokenSource?.cancel();
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
    for (var listener in _forwardStatusListener) {
      listener.onForwardServerStatusChanged(status);
    }
  }

  //endregion

  ///断开所有通过中转服务器的连接
  Future<void> _disconnectForwardSockets() async {
    final sessions = _sessions.snapshot();
    for (final session in sessions) {
      if (!session.socket.isForwardMode) continue;
      await _closeCurrentSession(
        session.dev.guid,
        session.socket,
        reason: 'forward control closed',
        autoReconnect: false,
      );
    }
  }

  Future<void> _onForwardServerReceived(Map<String, dynamic> data) async {
    final type = ForwardMsgType.getValue(data["type"]);
    switch (type) {
      case ForwardMsgType.ping:
        _lastForwardServerPingTime = DateTime.now();
        break;
      case ForwardMsgType.fileSyncNotAllowed:
        Global.showTipsDialog(
          context: Get.context!,
          text: TranslationKey.forwardServerNotAllowedSendFile.tr,
          title: TranslationKey.sendFailed.tr,
        );
        break;
      case ForwardMsgType.check:
        void disableForwardServerAfterDelay() {
          Future.delayed(500.ms, () {
            if (_forwardClient != null) return;
            appConfig.setEnableForward(false);
          });
        }
        if (!data.containsKey("result")) {
          Global.showTipsDialog(
            context: Get.context!,
            text: "${TranslationKey.forwardServerUnknownResult.tr}:\n ${data.toString()}",
            title: TranslationKey.forwardServerConnectFailed.tr,
          );
          disableForwardServerAfterDelay();
          return;
        }
        final result = data["result"];
        if (result == "success") {
          return;
        }
        disableForwardServerAfterDelay();
        Global.showTipsDialog(
          context: Get.context!,
          text: result,
          title: TranslationKey.forwardServerConnectFailed.tr,
        );
        break;
      case ForwardMsgType.requestConnect:
        final targetId = data["sender"];
        unawaited(manualConnectByForward(targetId));
        break;
      case ForwardMsgType.version:
        final version = data["version"]?.toString();
        appConfig.transportServerVersion.value = version ?? "";
        break;
      case ForwardMsgType.sendFile:
        final targetId = data["sender"];
        final size = data["size"].toString().toInt();
        final fileName = data["fileName"];
        final fileId = data["fileId"].toString().toInt();
        final userId = data["userId"].toString().toInt();
        //连接中转接收文件
        try {
          await FileSyncHandler.receiveFile(
            isForward: true,
            ip: forwardServerHost!,
            port: forwardServerPort!,
            size: size,
            fileName: fileName,
            devId: targetId,
            userId: userId,
            fileId: fileId,
            context: Get.context!,
            targetId: targetId,
          );
        } catch (err, stack) {
          logger.debug(
            tag,
            "receive file failed from forward"
            "$err $stack",
          );
        }
        break;
      case ForwardMsgType.fileReceiverConnected:
        //接收方已连接，开始发送
        final fileId = data["fileId"].toString().toInt();
        if (_forwardFiles.containsKey(fileId)) {
          _forwardFiles[fileId]!.onForwardReceiverConnected();
        } else {
          logger.warn(tag, "fileReceiverConnected but not fileId in waiting list");
        }
        break;
      default:
    }
  }

  ///socket 监听消息处理
  Future<void> _onSocketReceived(
    SecureSocketClient client,
    MessageData msg,
  ) async {
    DevInfo dev = msg.send;
    logger.debug(tag, "${dev.name} ${msg.key}");
    var address = _pendingPairingAddresses.firstWhereOrNull((ip) => ip.split(":")[0] == client.ip);
    switch (msg.key) {
      case MsgType.ping:
        break;

      case MsgType.pingResult:
        break;

      case MsgType.connect:
      case MsgType.pairedStatus:
        logger.debug(tag, "Ignore post-ready handshake message. device=${dev.guid}, key=${msg.key.name}");
        break;

      ///主动断开连接
      case MsgType.disConnect:
        await _closeCurrentSession(
          dev.guid,
          client,
          reason: 'remote disconnect',
          autoReconnect: false,
        );
        break;

      ///忘记设备
      case MsgType.forgetDev:
        await onDevForget(dev, appConfig.userId);
        break;

      ///单条数据同步
      case MsgType.ackSync:
      case MsgType.sync:
        _onSyncMsg(msg);
        break;

      ///批量数据同步
      case MsgType.missingData:
        var copyMsg = MessageData.fromJson(msg.toJson());
        var data = msg.data["data"] as Map<dynamic, dynamic>;
        copyMsg.data = data.cast<String, dynamic>();
        final total = msg.data["total"];
        int seq = msg.data["seq"];
        final syncProgressService = Get.find<HistorySyncProgressService>();
        syncProgressService.addProgress(copyMsg.send.guid, copyMsg.data, seq, total, false);
        _onSyncMsg(copyMsg);
        break;

      ///请求批量同步
      case MsgType.reqMissingData:
        var syncedAppIds = ((msg.data["appIds"] ?? []) as List<dynamic>).cast<String>();
        MissingDataSyncHandler.sendMissingData(dev, appConfig.device.guid, syncedAppIds);
        break;
      case MsgType.reqAppInfo:
        final appId = msg.data["appId"];
        final sourceService = Get.find<ClipboardSourceService>();
        logger.debug(tag, "await loadFuture");
        await sourceService.loadFuture;
        logger.debug(tag, "loadFuture completed");
        final appInfo = sourceService.getAppInfoByAppId(appId);
        if(appInfo == null){
          logger.debug(tag, "not found app info $appId");
          break;
        }
        logger.debug(tag, "found app info $appId");
        dev.sendData(MsgType.appInfo, appInfo.toJson());
        break;
      case MsgType.appInfo:
        final appInfo = AppInfo.fromJson(msg.data);
        final sourceService = Get.find<ClipboardSourceService>();

        final ruleController = Get.find<RulesController>();
        final notExists = ruleController.isNotExistAppInfo(appInfo.appId);
        if(appInfo.id == 0){
          appInfo.id = appInfo.appId.hash64;
        }
        final success = await sourceService.addOrUpdate(appInfo);
        if(success && notExists){
          ruleController.update();
        }
        break;

      ///请求配对我方，生成四位配对码
      case MsgType.reqPairing:
        final random = Random();
        int code = 100000 + random.nextInt(900000);
        DevPairingHandler.addCode(dev.guid, CryptoUtil.toMD5(code));
        //发送通知
        _pairingNotifyId = await NotifyUtil.notify(
          content: "${TranslationKey.devicePairingRequestNotificationContent.tr}: $code",
          key: "dev-pairing-${dev.guid}",
        );
        if (_pairing) {
          Get.back();
        }
        _pairing = true;
        showDialog(
          context: Get.context!,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(TranslationKey.devicePairingRequestDialogTitle.tr),
              content: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(TranslationKey.pairingCodeDialogContent.trParams({"devName": dev.name})),
                    const SizedBox(
                      height: 10,
                    ),
                    Text(
                      code.toString().split("").join("  "),
                      style: const TextStyle(fontSize: 30),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    cancelPairing(dev);
                  },
                  child: Text(TranslationKey.cancelCurrentPairing.tr),
                ),
              ],
            );
          },
        );
        break;

      ///请求配对我方，验证配对码
      case MsgType.pairing:
        String code = msg.data["code"];
        //验证配对码
        var verify = DevPairingHandler.verify(dev.guid, code);
        await _onDevPaired(dev, msg.userId, verify, address);
        //返回配对结果
        dev.sendData(MsgType.paired, {"result": verify}, false);
        _pendingPairingAddresses.removeWhere((v) {
          return v == address;
        });
        break;

      ///获取配对结果
      case MsgType.paired:
        bool result = msg.data["result"];
        await _onDevPaired(dev, msg.userId, result, address);
        _pendingPairingAddresses.removeWhere((v) => v == address);
        if (_pairing = true) {
          Get.back();
          _pairing = false;
        }
        break;

      ///取消配对
      case MsgType.cancelPairing:
        DevPairingHandler.removeCode(dev.guid);
        if (_pairing) {
          Get.back();
        }
        _onCancelPairing(dev);
        break;

      ///文件同步
      case MsgType.file:
        String ip = client.ip;
        int port = msg.data["port"];
        int size = msg.data["size"];
        String fileName = msg.data["fileName"];
        int fileId = msg.data["fileId"];
        try {
          await FileSyncHandler.receiveFile(
            ip: ip,
            port: port,
            size: size,
            fileName: fileName,
            devId: msg.send.guid,
            userId: msg.userId,
            fileId: fileId,
            context: Get.context!,
          );
        } catch (err, stack) {
          logger.debug(
            tag,
            "receive file failed. ip:$ip, port: $port, size: $size, fileName: $fileName. "
            "$err $stack",
          );
        }
        break;
      default:
    }
  }

  void cancelPairing(DevInfo dev) {
    if (!_pairing) return;
    DevPairingHandler.removeCode(dev.guid);
    Get.back();
    dev.sendData(MsgType.cancelPairing, {}, false);
    if (_pairingNotifyId != null) {
      NotifyUtil.cancel("dev-pairing-${dev.guid}", _pairingNotifyId!);
    }
    _pairing = false;
    _pairingNotifyId = null;
  }

  ///数据同步处理
  void _onSyncMsg(MessageData msg) {
    Module module = Module.getValue(msg.data["module"]);
    logger.debug(tag, "module ${module.moduleName}");
    final opId = _syncAckOpId(msg);
    final isReceivedSync = msg.key == MsgType.sync || msg.key == MsgType.missingData;
    final shouldAckReceivedSync = isReceivedSync && opId != null && module != Module.unknown;
    if (isReceivedSync && !shouldAckReceivedSync) {
      logger.warn(
        tag,
        "skip sync ack because message is not recognizable. "
        "key=${msg.key.name}, data=${jsonEncode(msg.data)}",
      );
    }
    //筛选某个模块的同步处理器
    var lst = getListeners(module);
    if (isReceivedSync) {
      dbService.execSequentially(() async {
        try {
          for (var listener in lst) {
            await listener.onSync(msg);
          }
        } finally {
          if (shouldAckReceivedSync) {
            await AckSyncSender.send(
              msg.send,
              opId,
              {
                "id": opId,
                "module": module.moduleName,
              },
            );
          }
        }
      });
      return;
    }
    for (var listener in lst) {
      switch (msg.key) {
        case MsgType.ackSync:
          dbService.execSequentially(() => listener.ackSync(msg));
          break;
        default:
          break;
      }
    }
  }

  /// 读取同步消息的原始操作 id，只有能定位发送端 OperationRecord 时才允许公共层回 ACK。
  int? _syncAckOpId(MessageData msg) {
    final id = msg.data["id"];
    if (id is int) {
      return id;
    }
    if (id is String) {
      return int.tryParse(id);
    }
    return null;
  }

  /// 当前是否正在执行发现流程，避免并发发现互相取消。
  var _discovering = false;

  bool get discovering => _discovering;

  ///发现设备
  void startDiscoveryDevices({
    bool restart = false,
    bool scan = true,
    bool manual = false,
  }) async {
    if (_discovering) {
      logger.debug(tag, "正在发现设备");
      return;
    }
    if (appConfig.currentNetWorkType.value == ConnectivityResult.none) {
      logger.debug(tag, "无网络");
      return;
    }
    _discovering = true;
    for (var listener in _discoverListeners) {
      listener.onDiscoverStart();
    }
    logger.debug(tag, "开始发现设备");
    onDiscoveryStopped() {
      //设备发现流程结束
      appConfig.deviceDiscoveryStatus.value = null;
      if (!_discoveryTokenSource.token.isCanceled) {
        _discoveryTokenSource.cancel();
      }
      _discovering = false;
      for (var listener in _discoverListeners) {
        listener.onDiscoverFinished();
      }
    }

    //更新设备发现控制令牌
    _discoveryTokenSource = CancelTokenSource();

    //重新更新广播监听
    try {
      if (!appConfig.onlyForwardMode) {
        await _startListenMulticast();
      }
    } catch (err, stack) {
      logger.error(tag, "error: $err", stack);
    }
    //尝试连接中转服务器
    if (_forwardClient == null) {
      await connectForwardServer();
    }

    //设备发现控制令牌
    var token = _discoveryTokenSource.token;
    //发现已配对设备
    if (token.isCanceled) {
      onDiscoveryStopped();
      return;
    }
    appConfig.deviceDiscoveryStatus.value = TranslationKey.deviceDiscoveryStatusViaPaired.tr;
    final List<Future<void> Function()> pairedDiscoveryTasks = appConfig.onlyForwardMode ? [] : await _pairedDiscovering();
    await ParallelTask(tasks: pairedDiscoveryTasks, maxParallelCnt: maxParallelCnt, token: token).run();

    //广播发现
    if (token.isCanceled) {
      onDiscoveryStopped();
      return;
    }
    appConfig.deviceDiscoveryStatus.value = TranslationKey.deviceDiscoveryStatusViaBroadcast.tr;
    final isMobileNetwork = appConfig.currentNetWorkType.value == ConnectivityResult.mobile && PlatformExt.isMobile;
    final List<Future<void> Function()> multicastDiscoveryTasks = isMobileNetwork || !scan ? [] : _multicastDiscovering();
    await ParallelTask(tasks: multicastDiscoveryTasks, maxParallelCnt: 1, token: token).run();

    //子网扫描
    if (token.isCanceled) {
      onDiscoveryStopped();
      return;
    }
    appConfig.deviceDiscoveryStatus.value = TranslationKey.deviceDiscoveryStatusViaScan.tr;
    final List<Future<void> Function()> subnetDiscoveryTasks = isMobileNetwork || !scan || appConfig.onlyForwardMode ? [] : await _subNetDiscovering(manual);
    await ParallelTask(tasks: subnetDiscoveryTasks, maxParallelCnt: maxParallelCnt, token: token).run();

    //中转发现
    if (token.isCanceled) {
      onDiscoveryStopped();
      return;
    }
    appConfig.deviceDiscoveryStatus.value = TranslationKey.deviceDiscoveryStatusViaForward.tr;
    final List<Future<void> Function()> forwardDiscoveryTasks = scan ? await _forwardDiscovering() : [];
    await ParallelTask(tasks: forwardDiscoveryTasks, maxParallelCnt: maxParallelCnt, token: token).run();
    onDiscoveryStopped();
  }

  ///停止发现设备
  Future<void> stopDiscoveryDevices([bool restart = false]) async {
    appConfig.deviceDiscoveryStatus.value = null;
    logger.debug(tag, "停止发现设备");
    if (!_discoveryTokenSource.token.isCanceled) {
      _discoveryTokenSource.cancel();
    }
    _discovering = false;
    _broadcastConnectionRequests.clear();
    _closeMulticastSockets();
    if (!restart) {
      for (var listener in _discoverListeners) {
        listener.onDiscoverFinished();
      }
    }
  }

  ///重新发现设备
  void restartDiscoveryDevices() async {
    logger.debug(tag, "重新开始发现设备");
    await stopDiscoveryDevices(true);
    startDiscoveryDevices(restart: true);
  }

  ///组播发现设备
  List<Future<void> Function()> _multicastDiscovering() {
    List<Future<void> Function()> tasks = List.empty(growable: true);
    for (var ms in const [100, 500, 2000, 5000]) {
      f() {
        return Future.delayed(ms.ms, () {
          // 广播本机socket信息
          Map<String, dynamic> map = {"port": _server.port};
          sendMulticastMsg(MsgType.broadcastInfo, map);
        });
      }

      tasks.add(() => f());
    }
    return tasks;
  }

  ///发现子网设备
  Future<List<Future<void> Function()>> _subNetDiscovering(bool manual) async {
    List<Future<void> Function()> tasks = List.empty(growable: true);
    //自动设备发现但是设置了仅手动触发
    if (!manual && appConfig.onlyManualDiscoverySubNet) {
      return tasks;
    }
    final interfaces = (await NetworkUtil.listInterfaces())
        .where((itf) => !appConfig.noDiscoveryIfs.contains(itf.name));
    final expendAddress = interfaces.map((itf) => itf.addresses).expand((address) => address);
    final ipv4Address = expendAddress.where((address) => address.type == InternetAddressType.IPv4);
    for (var address in ipv4Address) {
      final itfIp = address.address;
      //生成所有 ip
      final ipList = List.generate(255, (i) => '${itfIp.split('.').take(3).join('.')}.$i');
      //对每个ip尝试连接
      for (var genIp in ipList) {
        //从指定网卡出去
        tasks.add(() => manualConnect(genIp, sourceAddress: itfIp));
      }
    }
    return tasks;
  }

  ///发现已配对设备
  Future<List<Future<void> Function()>> _pairedDiscovering() async {
    List<Future<void> Function()> tasks = List.empty(growable: true);
    var devices = await dbService.deviceDao.getAllDevices(appConfig.userId);
    //先内网地址直连，若失败则尝试中转
    for (var dev in devices) {
      if (dev.internalAddress != null) {
        //内网地址不为空，尝试直连
        var [ip, port] = dev.internalAddress!.split(":");
        tasks.add(() async {
          try {
            final result = await manualConnect(ip, port: int.parse(port), targetDevId: dev.guid);
            if (!result) {
              //直连失败，尝试中转
              if (forwardServerHost.isNotNullAndEmpty) {
                await manualConnectByForward(dev.guid);
              }
            }
          } catch (err, stack) {
            logger.error(tag, err, stack);
            //直连过程异常，尝试中转
            if (forwardServerHost.isNotNullAndEmpty) {
              await manualConnectByForward(dev.guid);
            }
          }
        });
      } else {
        //内网地址为空，尝试中转
        if (forwardServerHost.isNotNullAndEmpty) {
          logger.debug(tag, "connect by forward ${dev.name}(${dev.guid})");
          tasks.add(() => manualConnectByForward(dev.guid));
        }
      }
    }
    return tasks;
  }

  ///中转连接
  Future<List<Future<void> Function()>> _forwardDiscovering() async {
    List<Future<void> Function()> tasks = List.empty(growable: true);
    if (_forwardClient == null) return tasks;
    if (appConfig.forwardWay != ForwardWay.server) {
      logger.debug(tag, "_forwardDiscovering forward way is ${appConfig.forwardWay.name}");
      return tasks;
    }
    var lst = await dbService.deviceDao.getAllDevices(appConfig.userId);
    for (var dev in lst) {
      if (forwardServerHost == null || forwardServerPort == null) continue;
      tasks.add(() => manualConnectByForward(dev.guid));
    }
    return tasks;
  }

  ///检查是否已经掉线，如果掉线则移除
  Future<bool> testIsOnline(String devId, { bool autoReconnect = true }) async {
    final session = _sessions.get(devId);
    if (session == null) {
      return false;
    }
    final online = await session.socket.testOnline();
    if (online) {
      return true;
    }
    await _closeCurrentSession(
      devId,
      session.socket,
      reason: 'online probe failed',
      autoReconnect: autoReconnect,
    );
    return false;
  }

  ///中转连接设备
  Future<bool> manualConnectByForward(String devId, {CancelToken? cancelToken}) async {
    if (appConfig.forwardWay != ForwardWay.server || forwardServerHost == null || forwardServerPort == null) {
      logger.debug(tag, "manualConnectByForward skipped for mode ${appConfig.forwardWay.name}");
      return false;
    }
    final address = "${forwardServerHost!}:${forwardServerPort!}:$devId";
    final running = _inFlightConnectionRequests[address];
    if (running != null) {
      return running;
    }
    final tokenSource = CancelTokenSource();
    final token = _combineCancelTokens(tokenSource.token, cancelToken);
    final request = DeviceConnectionRequest(
      workerKey: devId,
      expectedDevId: devId,
      description: 'manual forward connect',
      token: token,
      connect: (token) {
        return SecureSocketClient.connect(
          ip: forwardServerHost!,
          port: forwardServerPort!,
          prime1: appConfig.prime1,
          prime2: appConfig.prime2,
          dhAesKey: appConfig.dhAesKey,
          targetDevId: devId,
          selfDevId: appConfig.device.guid,
          connectionMode: ConnectionMode.forward,
          onMessage: (client, json) {
            final msg = MessageData.fromJson(json);
            unawaited(_onSocketReceived(client, msg));
          },
          onDone: (client) => _onClientTransportClosed(client, reason: 'forward device done'),
          onError: (error, client) => _onClientTransportClosed(client, reason: 'forward device error: $error'),
          cancelToken: token,
        );
      },
    );
    final future = _enqueueDeviceConnection(request);
    _inFlightConnectionRequests[address] = future;
    try {
      return await future;
    } finally {
      if (identical(_inFlightConnectionRequests[address], future)) {
        _inFlightConnectionRequests.remove(address);
      }
    }
  }

  ///手动连接 ip
  Future<bool> manualConnect(
    String host, {
    String? sourceAddress,
    int? port,
    Function? onErr,
    Map<String, dynamic> data = const {},
    bool forward = false,
    String? targetDevId,
    CancelToken? cancelToken,
  }) async {
    port = port ?? Constants.port;
    if (forward && targetDevId != null) {
      return manualConnectByForward(targetDevId, cancelToken: cancelToken);
    }
    final address = "$host:$port:$targetDevId";
    final running = _inFlightConnectionRequests[address];
    if (running != null) {
      return running;
    }
    Future<bool>? submittedFuture;
    try {
      if (data['stop'] == true || (cancelToken?.isCanceled ?? false)) {
        return false;
      }
      final tokenSource = CancelTokenSource();
      final token = _combineCancelTokens(tokenSource.token, cancelToken);
      final request = DeviceConnectionRequest(
        workerKey: targetDevId ?? address,
        expectedDevId: targetDevId,
        description: 'manual direct connect $host:$port',
        token: token,
        connect: (token) {
          return SecureSocketClient.connect(
            ip: host,
            sourceAddress: sourceAddress,
            port: port!,
            prime1: appConfig.prime1,
            prime2: appConfig.prime2,
            dhAesKey: appConfig.dhAesKey,
            onMessage: (client, json) {
              final msg = MessageData.fromJson(json);
              unawaited(_onSocketReceived(client, msg));
            },
            onDone: (client) => _onClientTransportClosed(client, reason: 'manual direct done'),
            onError: (error, client) => _onClientTransportClosed(client, reason: 'manual direct error: $error'),
            cancelToken: token,
          );
        },
      );
      submittedFuture = _enqueueDeviceConnection(request);
      _inFlightConnectionRequests[address] = submittedFuture;
      final result = await submittedFuture;
      if (result) {
        _pendingPairingAddresses.add("$host:$port");
      }
      return result;
    } catch (error, stackTrace) {
      logger.debug(tag, 'Manual Socket connect failed. host=$host, port=$port, error=$error $stackTrace');
      onErr?.call(error);
      return false;
    } finally {
      if (identical(_inFlightConnectionRequests[address], submittedFuture)) {
        _inFlightConnectionRequests.remove(address);
      }
    }
  }
  ///判断某个设备使用使用中转
  bool isUseForward(String guid) {
    final session = _sessions.get(guid);
    if (session == null) return false;
    return session.socket.isForwardMode;
  }

  Future<void> reqMissingData([String? devId]) async {
    final sourceService = Get.find<ClipboardSourceService>();
    if (devId != null) {
      final devSkt = _sessions.get(devId);
      if (devSkt == null) {
        return;
      }
      final allAppInfos = sourceService.appInfos;
      final ownedAppIds = allAppInfos.where((item) => item.devId == devId).map((item) => item.appId).toList();
      await devSkt.dev.sendData(MsgType.reqMissingData, {
        "appIds": ownedAppIds,
      });
    } else {
      if (!appConfig.autoSyncMissingData) {
        return;
      }
      final devs = _sessions.snapshot().where((dev) => dev.isPaired).map(((item) => item.dev)).toList();
      final allAppInfos = sourceService.appInfos;
      for (var dev in devs) {
        final ownedAppIds = allAppInfos.where((item) => item.devId == dev.guid).map((item) => item.appId).toList();
        await dev.sendData(MsgType.reqMissingData, {
          "appIds": ownedAppIds,
        });
      }
    }
  }

  ///设备连接成功
  Future<void> _onDevConnected(
    DevInfo dev,
    SecureSocketClient client,
    AppVersion minVersion,
    AppVersion version,
  ) async {
    devConnNotifyService.showConnected(
      dev.guid,
      isPaired: _sessions.get(dev.guid)?.isPaired ?? false,
    );
    final ip = client.ip;
    final port = client.isForwardMode ? forwardServerPort : client.port;

    //更新连接地址
    final address = "$ip:$port";
    if (address.isInternalIPv4) {
      await dbService.deviceDao.updateDeviceInternalAddress(dev.guid, appConfig.userId, address);
    }
    await dbService.deviceDao.updateDeviceAddress(dev.guid, appConfig.userId, address);
    //添加到注册服务
    _registry.addDevice(dev, client.isForwardMode ? TransportProtocol.server : TransportProtocol.direct);
    _broadcastConnectionRequests.remove(dev.guid);
    for (var listener in _devAliveListeners) {
      try {
        await listener.onConnected(
          dev,
          minVersion,
          version,
          client.isForwardMode ? TransportProtocol.server : TransportProtocol.direct,
        );
      } catch (e, t) {
        logger.debug(tag, "$e $t");
      }
    }
  }

  ///断开所有连接
  void disConnectAllConnections([bool onlyNotPaired = false]) {
    logger.debug(tag, "开始断开所有连接 仅未配对：$onlyNotPaired");
    if (!onlyNotPaired) {
      disConnectForwardServer();
    }
    var skts = _sessions.snapshot();
    for (var devSkt in skts) {
      if (onlyNotPaired && devSkt.isPaired) {
        continue;
      }
      unawaited(disconnectDevice(devSkt.dev, true));
    }
  }

  ///主动断开设备连接
  Future<bool> disconnectDevice(DevInfo dev, bool backSend) async {
    var id = dev.guid;
    final session = _sessions.get(id);
    if (session == null) {
      return false;
    }
    await _closeCurrentSession(
      id,
      session.socket,
      reason: 'manual disconnect',
      autoReconnect: false,
      sendDisconnect: backSend,
    );
    return true;
  }

  ///设备配对成功
  Future<void> _onDevPaired(DevInfo dev, int uid, bool result, String? address) async {
    logger.debug(tag, "${dev.name} paired，address：$address");
    _sessions.get(dev.guid)?.isPaired = result;
    if (result) {
      final protocol = (address?.isInternalIPv4 ?? false) ? TransportProtocol.direct : TransportProtocol.server;
      final dbDev = await dbService.deviceDao.getById(dev.guid, appConfig.userId);
      await devService.confirmPairingState(
        device: dbDev ??
            Device(
              guid: dev.guid,
              devName: dev.name,
              uid: uid,
              type: dev.type,
              internalAddress: (address?.isInternalIPv4 ?? false) ? address : null,
              address: address,
            ),
        localIsPaired: true,
        remoteIsPaired: true,
        protocol: protocol,
        manual: true,
      );
    }
    for (var listener in _devAliveListeners) {
      try {
        listener.onPaired(dev, uid, result, address);
      } catch (e, t) {
        logger.debug(tag, "$e $t");
      }
    }
  }

  ///设备取消配对
  void _onCancelPairing(DevInfo dev) {
    logger.debug(tag, "${dev.name} cancelPairing");
    if (_pairingNotifyId != null) {
      NotifyUtil.cancel("dev-pairing-${dev.guid}", _pairingNotifyId!);
    }
    _pairing = false;
    _pairingNotifyId = null;
    for (var listener in _devAliveListeners) {
      try {
        listener.onCancelPairing(dev);
      } catch (e, t) {
        logger.debug(tag, "$e $t");
      }
    }
  }

  ///设备配对成功
  Future<void> onDevForget(
    DevInfo dev,
    int uid, {
    bool updatePairingState = true,
  }) async {
    logger.debug(tag, "${dev.name} forget");
    _sessions.get(dev.guid)?.isPaired = false;
    final session = _sessions.get(dev.guid);
    if (updatePairingState) {
      final dbDev = await dbService.deviceDao.getById(dev.guid, appConfig.userId);
      await devService.confirmPairingState(
        device: dbDev ??
            Device(
              guid: dev.guid,
              devName: dev.name,
              uid: uid,
              type: dev.type,
        ),
        localIsPaired: false,
        remoteIsPaired: false,
        protocol: session?.socket.isForwardMode ?? false ? TransportProtocol.server : TransportProtocol.direct,
        manual: true,
      );
    }
    for (var listener in _devAliveListeners) {
      try {
        listener.onForget(dev, uid);
      } catch (e, t) {
        logger.debug(tag, "$e $t");
      }
    }
  }

  //region 心跳相关
  /// 注册 Socket 心跳任务，统一交给传输心跳服务管理定时器。
  void _registerSocketHeartbeatTask() {
    transportHeartbeatService.registerTask(
      TransportHeartbeatTask(
        name: _socketHeartbeatTaskName,
        shouldRun: () => true,
        onTick: (trigger) {
          // 定时心跳没有在线 Socket 时不发送，首次启动立即 ping。
          if (trigger == TransportHeartbeatTrigger.timer && _sessions.isEmpty) {
            return;
          }
          if (trigger == TransportHeartbeatTrigger.timer) {
            logger.debug(tag, "send ping");
          }
          DataSender.sendData2All(MsgType.ping, {}, false);
        },
        onStop: (reason) {
          if (reason != TransportHeartbeatStopReason.screenOffAutoClose) {
            return;
          }
          // 息屏到期时断开所有连接并停止中转服务存活判断。
          logger.debug(tag, "屏幕关闭时间已到，断开所有连接和心跳测试");
          disConnectAllConnections();
          _stopJudgeForwardClientAlive();
        },
      ),
    );
  }

  ///开始所有设备的心跳测试
  void startHeartbeatTest() {
    transportHeartbeatService.start(_socketHeartbeatTaskName);
  }

  ///停止所有设备的心跳测试
  void stopHeartbeatTest() {
    transportHeartbeatService.stop(_socketHeartbeatTaskName);
  }

  ///定时判断中转服务连接存活状态
  void _startJudgeForwardClientAlivePeriod() {
    //先停止
    if (_forwardClientHeartbeatTimer != null) {
      _stopJudgeForwardClientAlive();
    }
    //更新timer
    _forwardClientHeartbeatTimer = Timer.periodic(35.s, (timer) {
      var disconnected = false;
      if (_lastForwardServerPingTime == null) {
        disconnected = true;
      } else {
        final now = DateTime.now();
        if (now.difference(_lastForwardServerPingTime!).inSeconds >= 35) {
          disconnected = true;
        }
      }
      logger.debug(tag, "startJudgeForwardClientAlivePeriod disconnected: $disconnected");
      if (!disconnected) return;
      final client = _forwardClient;
      if (client == null) return;
      _handleForwardClientDisconnected(
        client,
        "forward control heartbeat timeout",
        closeClient: true,
      );
    });
  }

  ///停止定时判断中转服务连接存活状态
  void _stopJudgeForwardClientAlive() {
    _forwardClientHeartbeatTimer?.cancel();
    _forwardClientHeartbeatTimer = null;
  }

  @override
  void onScreenOpened() {
    screenOpened = true;
    if (_forwardClient == null) {
      connectForwardServer();
    }
    startDiscoveryDevices(scan: appConfig.enableAutoSyncOnScreenOpened);
    logger.debug(tag, "屏幕打开");
  }

  @override
  void onScreenClosed() {
    super.onScreenClosed();
    logger.debug(tag, "屏幕关闭");
    screenOpened = false;
    if (!appConfig.autoCloseConnAfterScreenOff) {
      return;
    }
    logger.debug(tag, "屏幕关闭，等待统一心跳管理服务到期后关闭连接");
  }

  //endregion

  ///重连一次
  Future<void> reconnectOnce(String guid) async {
    await _attemptReconnect(guid, true);
  }

  /// 为单个设备启动唯一重连循环；新循环会取消同设备旧循环和队列中的旧候选。
  Future<void> _attemptReconnect(String guid, [bool once = false]) async {
    final running = _reconnectTasks[guid];
    if (running != null) {
      return running;
    }
    final tokenSource = CancelTokenSource();
    _reconnectTokenSources[guid]?.cancel();
    _reconnectTokenSources[guid] = tokenSource;
    late final Future<void> task;
    task = _runReconnectLoop(guid, tokenSource.token, once).whenComplete(() {
      if (identical(_reconnectTasks[guid], task)) {
        _reconnectTasks.remove(guid);
      }
      if (identical(_reconnectTokenSources[guid], tokenSource)) {
        _reconnectTokenSources.remove(guid);
      }
    });
    _reconnectTasks[guid] = task;
    return task;
  }

  /// 按“内网优先，失败再中转”的顺序重连，取消令牌失效后立即停止派发新连接。
  Future<void> _runReconnectLoop(String guid, CancelToken token, bool once) async {
    final dev = await dbService.deviceDao.getById(guid, appConfig.userId);
    if (dev == null) {
      logger.warn(tag, "Device $guid not found in db");
      return;
    }
    final deadline = DateTime.now().add(once ? Duration.zero : Constants.socketReconnectWindow);
    var attempted = false;
    while (!token.isCanceled && !_disposed && (once ? !attempted : DateTime.now().isBefore(deadline))) {
      if (!once) {
        await Future.delayed(Constants.socketReconnectInterval);
      }
      if (token.isCanceled || _disposed) {
        return;
      }
      attempted = true;
      if (await testIsOnline(guid, autoReconnect: false)) {
        final devSkt = _sessions.get(guid);
        logger.debug(tag, "Reconnect succeeded. device=${dev.name}(${devSkt!.socket.ip}:${devSkt.socket.port})");
        return;
      }
      if (appConfig.currentNetWorkType.value == ConnectivityResult.none) {
        logger.debug(tag, "Reconnect stopped because network is unavailable. device=${dev.name}");
        return;
      }
      try {
        logger.debug(tag, "Reconnect attempt. device=${dev.name}, internalAddress=${dev.internalAddress}");
        var connected = false;
        final internalAddress = dev.internalAddress;
        if (internalAddress != null) {
          final parts = internalAddress.split(":");
          if (parts.length == 2) {
            connected = await manualConnect(
              parts[0],
              port: parts[1].toInt(),
              targetDevId: guid,
              cancelToken: token,
            );
          }
        }
        if (!connected && _forwardClient != null) {
          await _delayBeforeForwardReconnect(guid, token);
          if (token.isCanceled || _disposed || _forwardClient == null) {
            return;
          }
          connected = await manualConnectByForward(guid, cancelToken: token);
        }
        if (connected) {
          return;
        }
      } catch (error, stackTrace) {
        logger.debug(tag, "Reconnect attempt failed. device=$guid, error=$error $stackTrace");
      }
    }
    logger.debug(tag, "Reconnect window ended. device=${dev.name}(${dev.guid})");
  }

  /// 自动重连转入中转前做确定性错峰，避免两端网络同时恢复时持续同步发起中转候选。
  Future<void> _delayBeforeForwardReconnect(String targetDevId, CancelToken token) async {
    final skew = _calcForwardReconnectSkew(targetDevId);
    if (skew == Duration.zero || token.isCanceled || _disposed) {
      return;
    }
    await Future.delayed(skew);
  }

  /// 使用本机与目标设备 id 计算稳定错峰；同一设备对两端会落在不同时间点。
  Duration _calcForwardReconnectSkew(String targetDevId) {
    final localDevId = appConfig.device.guid;
    final seed = "$localDevId->$targetDevId";
    var hash = 0;
    for (final codeUnit in seed.codeUnits) {
      hash = (hash * 31 + codeUnit) & 0x7fffffff;
    }
    final maxMs = _forwardReconnectMaxSkew.inMilliseconds;
    return Duration(milliseconds: hash % (maxMs + 1));
  }

  /// 取消同设备当前重连令牌，旧循环自然观察 token 后退出。
  void _cancelReconnect(String guid) {
    _reconnectTokenSources.remove(guid)?.cancel();
    _reconnectTasks.remove(guid);
  }

  /// 合并本次请求令牌和外部取消令牌，任一令牌取消都让候选连接失效。
  CancelToken _combineCancelTokens(CancelToken localToken, CancelToken? externalToken) {
    if (externalToken == null) {
      return localToken;
    }
    return _CompositeCancelToken(<CancelToken>[localToken, externalToken]);
  }

  ///向兼容的设备发送消息
  @override
  Future<void> sendData(
    DevInfo? dev,
    MsgType key,
    Map<String, dynamic> data, [
    bool onlyPaired = true,
  ]) async {
    Iterable<DeviceSocketSession> sessions;
    if (dev == null) {
      final snapshot = _sessions.snapshot();
      sessions = onlyPaired ? snapshot.where((dev) => dev.isPaired) : snapshot;
      sessions = sessions.where(
        (dev) => dev.version >= appConfig.minVersion,
      );
    } else {
      final session = _sessions.get(dev.guid);
      if (session == null) {
        logger.debug(tag, "${dev.name} 设备未连接，发送失败");
        return;
      }
      if (session.version < appConfig.minVersion) {
        logger.debug(tag, "${dev.name} 与当前设备版本不兼容");
        return;
      }
      sessions = [session];
    }
    final targets = sessions.toList(growable: false);
    for (final session in targets) {
      if (!_sessions.isCurrent(session.dev.guid, session.socket) || !session.socket.isReady) {
        continue;
      }
      final msg = MessageData(
        userId: appConfig.userId,
        send: appConfig.devInfo,
        key: key,
        data: data,
        recv: null,
      );
      logger.debug(tag, session.dev.name);
      try {
        await session.socket.send(msg.toJson());
      } catch (error, stackTrace) {
        logger.debug(tag, 'Socket send failed. device=${session.dev.guid}, error=$error $stackTrace');
        await _closeCurrentSession(
          session.dev.guid,
          session.socket,
          reason: 'send failed',
        );
      }
    }
  }
  /// 发送组播消息
  void sendMulticastMsg(
    MsgType key,
    Map<String, dynamic> data, [
    DevInfo? recv,
  ]) async {
    MessageData msg = MessageData(
      userId: appConfig.userId,
      send: appConfig.devInfo,
      key: key,
      data: data,
      recv: recv,
    );
    try {
      var b64Data = CryptoUtil.base64EncodeStr("${msg.toJsonStr()}\n");
      var multicasts = await _getSockets(Constants.multicastGroup);
      for (var multicast in multicasts) {
        multicast.send(
          utf8.encode(b64Data),
          InternetAddress(Constants.multicastGroup),
          appConfig.port,
        );
        multicast.close();
      }
    } catch (e, stacktrace) {
      logger.debug(tag, "$e $stacktrace");
    }
  }

  Future<List<RawDatagramSocket>> _getSockets(
    String multicastGroup, [
    int port = 0,
  ]) async {
    const ipv4Type = InternetAddressType.IPv4;
    final interfaces = (await NetworkUtil.listInterfaces())
        .where((itf) => !appConfig.noDiscoveryIfs.contains(itf.name))
        .where((itf) => itf.addresses.any((addr) => addr.type == ipv4Type));

    final sockets = <RawDatagramSocket>[];

    for (final interface in interfaces) {
      try {
        // 获取对应的IPv4地址
        final localAddr = interface.addresses.firstWhere((addr) => addr.type == ipv4Type);
        // 绑定到特定网卡和端口
        final socket = await RawDatagramSocket.bind(localAddr, port);
        // 加入多播组
        socket.joinMulticast(InternetAddress(multicastGroup), interface);
        sockets.add(socket);
      } catch (e, stack) {
        logger.error(tag, 'Failed to bind to ${interface.name}: $e', stack);
      }
    }

    return sockets;
  }

  ///添加中转文件发送记录
  void addSendFileRecordByForward(FileSyncHandler fileSyncer, int fileId) {
    if (_forwardFiles.containsKey(fileId)) {
      throw Exception("The file is already in the sending list: $fileId");
    }
    _forwardFiles[fileId] = fileSyncer;
  }

  ///移除中转文件发送记录
  void removeSendFileRecordByForward(
    FileSyncHandler fileSyncer,
    int fileId,
    String? targetDevId,
  ) {
    _forwardFiles.remove(fileId);
    if (targetDevId != null) {
      _forwardClient?.send({
        "type": ForwardMsgType.cancelSendFile.name,
        "targetId": targetDevId,
      });
    }
  }
}

/// 多来源取消令牌用于连接候选，外部重连取消或本地请求取消任一发生都应立即失效。
class _CompositeCancelToken extends CancelToken {
  final List<CancelToken> tokens;

  _CompositeCancelToken(this.tokens);

  @override
  bool get isCanceled => tokens.any((token) => token.isCanceled);
}
