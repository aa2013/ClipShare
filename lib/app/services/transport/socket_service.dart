import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:clipshare/app/data/enums/connection_mode.dart';
import 'package:clipshare/app/data/enums/forward_msg_type.dart';
import 'package:clipshare/app/data/enums/forward_way.dart';
import 'package:clipshare/app/data/enums/module.dart';
import 'package:clipshare/app/data/enums/msg_type.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/enums/transport_protocol.dart';
import 'package:clipshare/app/data/models/dev_info.dart';
import 'package:clipshare/app/data/models/end_point.dart';
import 'package:clipshare/app/data/models/message_data.dart';
import 'package:clipshare/app/data/repository/entity/tables/app_info.dart';
import 'package:clipshare/app/handlers/dev_pairing_handler.dart';
import 'package:clipshare/app/handlers/socket/forward_socket_client.dart';
import 'package:clipshare/app/handlers/socket/secure_socket_client.dart';
import 'package:clipshare/app/handlers/sync/abstract_data_sender.dart';
import 'package:clipshare/app/handlers/sync/file_sync_handler.dart';
import 'package:clipshare/app/handlers/sync/missing_data_sync_handler.dart';
import 'package:clipshare/app/listeners/dev_alive_listener.dart';
import 'package:clipshare/app/listeners/discover_listener.dart';
import 'package:clipshare/app/listeners/forward_status_listener.dart';
import 'package:clipshare/app/listeners/screen_opened_listener.dart';
import 'package:clipshare/app/services/clipboard_source_service.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/services/history_sync_progress_service.dart';
import 'package:clipshare/app/services/transport/connection_registry_service.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/crypto.dart';
import 'package:clipshare/app/utils/extensions/device_extension.dart';
import 'package:clipshare/app/utils/extensions/number_extension.dart';
import 'package:clipshare/app/utils/extensions/platform_extension.dart';
import 'package:clipshare/app/utils/extensions/string_extension.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:clipshare/app/utils/notify_util.dart';
import 'package:clipshare/app/utils/parallerl_task.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

typedef VoidFutureFunction = Future<void> Function();

class SocketService extends GetxService with ScreenOpenedObserver, DataSender {
  final appConfig = Get.find<ConfigService>();
  final connRegService = Get.find<ConnectionRegistryService>();
  final dbService = Get.find<DbService>();
  static const String tag = "SocketService";
  static const maxParallelCnt = 10;

  bool _isInit = false;

  //socket服务端
  late ServerSocket _server;

  //设备心跳检测定时器
  Timer? _heartbeatTimer;

  //广播 socket
  List<RawDatagramSocket> _multicasts = [];

  //标记是否正在设备发现
  bool _discovering = false;

  //设备发现控制令牌
  CancelTokenSource _discoveryTokenSource = CancelTokenSource();

  //设备待连接队列
  var pendingConnectionQueue = StreamController<DeviceEndPoint>();

  // 某设备的Socket连接，devId => DevSocket
  final Map<String, SecureSocketClient> _devSockets = {};

  //重连中的设备id
  final Set<String> _reconnectingDevIds = {};

  //配对通知 id, devId => notifyId
  final _pairingNotifyIds = <String, int?>{};

  //配对中的设备id
  final _pairingDevIds = <String>{};

  ForwardSocketClient? _forwardClient;

  //region dev registry
  final DeviceConnectionRegistry _registry;

  List<DevAliveListener> get _devAliveListeners => _registry.devAliveListeners;

  List<DiscoverListener> get _discoverListeners => _registry.discoverListeners;

  List<ForwardStatusListener> get _forwardStatusListener => _registry.forwardStatusListener;

  //endregion

  SocketService(this._registry);

  Future<SocketService> init() async {
    if (_isInit) throw Exception("已初始化");
    ScreenOpenedListener.inst.register(this);
    //启动服务端监听连接，广播监听，设备发现
    _runSocketServer();
    _runDeviceConnectTask();
    startHeartbeatTest();
    _isInit = true;
    return this;
  }

  ///region 服务端消息收发解析

  ///运行服务端 socket 监听消息同步
  _runSocketServer() async {
    _server = await ServerSocket.bind('0.0.0.0', appConfig.port);
    _server.listen(
      (socket) async {
        try {
          await _connect(socket: socket, isDirect: true);
        } catch (err, stack) {
          final endPoint = EndPoint(socket.remoteAddress.address, socket.remotePort);
          Log.error(tag, "error = $err, endPoint = $endPoint", stack);
        }
      },
    );
  }

  ///监听广播
  Future<void> _startListenMulticast() async {
    //关闭原本的监听
    for (var multicast in _multicasts) {
      multicast.close();
    }
    //重新监听
    _multicasts = await _getMulticastSockets(
      Constants.multicastGroup,
      appConfig.port,
    );
    for (var multicast in _multicasts) {
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
        if (msg.key != MsgType.broadcastInfo) {
          return;
        }
        try {
          var ip = datagram.address.address;
          var port = msg.data["port"].toString().toInt();
          pendingConnectionQueue.add(DeviceEndPoint(dev, ip, port));
        } catch (err, stack) {
          Log.error(tag, err, stack);
        }
      });
    }
  }

  ///获取广播 socket
  Future<List<RawDatagramSocket>> _getMulticastSockets(
    String multicastGroup, [
    int port = 0,
  ]) async {
    final interfaces = (await NetworkInterface.list()).where(
      (itf) => !appConfig.noDiscoveryIfs.contains(itf.name),
    );
    final sockets = <RawDatagramSocket>[];
    for (final interface in interfaces) {
      final socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        port,
      );
      socket.joinMulticast(InternetAddress(multicastGroup), interface);
      sockets.add(socket);
    }
    return sockets;
  }

  ///endregion

  ///region 设备发现

  ///开始设备发现
  ///[manual] 是否手动点击设备发现
  Future<void> startDiscoveryDevices({
    bool manual = false,
  }) async {
    Log.debug(tag, "进入设备发现逻辑");
    if (_discovering) {
      Log.debug(tag, "正在发现设备");
      return;
    }
    if (appConfig.currentNetWorkType.value == ConnectivityResult.none) {
      Log.debug(tag, "无网络，终止设备发现");
      _discovering = false;
      return;
    }
    _discovering = true;
    Log.debug(tag, "开始发现设备");
    for (var listener in _discoverListeners) {
      listener.onDiscoverStart();
    }

    ///设备发现停止
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
      Log.error(tag, "error: $err, $stack");
    }

    //todo 尝试连接中转服务器

    final token = _discoveryTokenSource.token;
    //发现已配对设备
    if (token.isCanceled) {
      onDiscoveryStopped();
      return;
    }
    appConfig.deviceDiscoveryStatus.value = TranslationKey.deviceDiscoveryStatusViaPaired.tr;
    Log.debug(tag, appConfig.deviceDiscoveryStatus.value);
    final List<VoidFutureFunction> pairedDiscoveryTasks = appConfig.onlyForwardMode ? [] : await _pairedDiscovering();
    await ParallelTask(tasks: pairedDiscoveryTasks, maxParallelCnt: maxParallelCnt, token: token).run();

    //广播发现
    if (token.isCanceled) {
      onDiscoveryStopped();
      return;
    }
    appConfig.deviceDiscoveryStatus.value = TranslationKey.deviceDiscoveryStatusViaBroadcast.tr;
    Log.debug(tag, appConfig.deviceDiscoveryStatus.value);
    final isMobileNetwork = appConfig.currentNetWorkType.value == ConnectivityResult.mobile && PlatformExt.isMobile;
    final List<VoidFutureFunction> multicastDiscoveryTasks = isMobileNetwork ? [] : _multicastDiscovering();
    await ParallelTask(tasks: multicastDiscoveryTasks, maxParallelCnt: 1, token: token).run();

    //子网扫描
    if (token.isCanceled) {
      onDiscoveryStopped();
      return;
    }
    appConfig.deviceDiscoveryStatus.value = TranslationKey.deviceDiscoveryStatusViaScan.tr;
    Log.debug(tag, appConfig.deviceDiscoveryStatus.value);
    final List<VoidFutureFunction> subnetDiscoveryTasks = isMobileNetwork || appConfig.onlyForwardMode ? [] : await _subNetDiscovering(manual);
    await ParallelTask(tasks: subnetDiscoveryTasks, maxParallelCnt: maxParallelCnt, token: token).run();

    //中转发现
    if (token.isCanceled) {
      onDiscoveryStopped();
      return;
    }
    appConfig.deviceDiscoveryStatus.value = TranslationKey.deviceDiscoveryStatusViaForward.tr;
    Log.debug(tag, appConfig.deviceDiscoveryStatus.value);
    final List<VoidFutureFunction> forwardDiscoveryTasks = await _forwardDiscovering();
    await ParallelTask(tasks: forwardDiscoveryTasks, maxParallelCnt: maxParallelCnt, token: token).run();
    onDiscoveryStopped();
  }

  ///停止设备发现
  Future<void> stopDiscoveryDevices([bool restart = false]) async {
    appConfig.deviceDiscoveryStatus.value = null;
    final isCanceled = _discoveryTokenSource.token.isCanceled;
    if (!isCanceled) {
      _discoveryTokenSource.cancel();
      Log.debug(tag, "已停止发现设备");
    }
    _discovering = false;
    if (!restart) {
      for (var listener in _discoverListeners) {
        listener.onDiscoverFinished();
      }
    }
  }

  ///重新开始设备发现
  Future<void> restartDiscoveryDevices() async {
    await stopDiscoveryDevices(true);
    await startDiscoveryDevices();
  }

  ///发现已连接设备
  List<VoidFutureFunction> _pairedDiscovering() {
    return [];
  }

  ///广播发现
  List<VoidFutureFunction> _multicastDiscovering() {
    List<VoidFutureFunction> tasks = [];
    for (var ms in const [100, 500, 2000, 5000]) {
      tasks.add(
        () => Future.delayed(ms.ms, () {
          // 广播本机socket信息
          Map<String, dynamic> map = {"port": _server.port};
          sendMulticastMsg(MsgType.broadcastInfo, map);
        }),
      );
    }
    return tasks;
  }

  ///发现子网设备
  ///[manual] 是否是手动执行设备发现
  Future<List<VoidFutureFunction>> _subNetDiscovering(bool manual) async {
    List<VoidFutureFunction> tasks = [];
    //自动设备发现但是设置了仅手动触发
    if (!manual && appConfig.onlyManualDiscoverySubNet) {
      return tasks;
    }
    var interfaces = (await NetworkInterface.list()).where((itf) => !appConfig.noDiscoveryIfs.contains(itf.name));
    var expendAddress = interfaces.map((itf) => itf.addresses).expand((ip) => ip);
    var ips = expendAddress.where((ip) => ip.type == InternetAddressType.IPv4).map((address) => address.address).toList();
    for (var ip in ips) {
      //生成所有 ip
      final ipList = List.generate(255, (i) => '${ip.split('.').take(3).join('.')}.$i').where((genIp) => genIp != ip).toList();
      //对每个ip尝试连接
      for (var genIp in ipList) {
        tasks.add(() async {
          try {
            await _connect(endPoint: EndPoint(genIp, appConfig.port), isDirect: true);
          } catch (_) {}
        });
      }
    }
    return tasks;
  }

  ///中转发现
  Future<List<VoidFutureFunction>> _forwardDiscovering() async {
    return [];
  }

  ///endregion

  ///设备连接
  Future<void> _runDeviceConnectTask() async {
    await for (final endpoint in pendingConnectionQueue.stream) {
      try {
        final devInfo = endpoint.devInfo;
        final devId = devInfo.guid;
        final host = endpoint.host;
        final port = endpoint.port;
        final devSkt = _devSockets[devId];
        if (devSkt != null && !devSkt.closed) {
          //如果已经连接，进行测试连接有效性，若连接有响应则忽略
          final isValid = await devSkt.testOnline();
          if (isValid) {
            continue;
          }
          //连接无效，先移除再关闭连接避免重复触发 onDone
          _devSockets.remove(devId);
          await devSkt.close();
          //通知观察者设备连接断开
          _notifyDeviceDisconnected(devSkt);
        }
        final endpointIsValid = await _testEndPointConnection(endpoint);
        if (!endpointIsValid) {
          continue;
        }
        //正式连接设备
        final endPoint = EndPoint(host, port);
        try {
          await _connect(endPoint: endPoint, isDirect: true);
        } catch (err, stack) {
          Log.error(tag, "error = $err, endPoint = $endPoint", stack);
          continue;
        }
      } catch (err, stack) {
        Log.error(tag, "error:$err, endpoint:$endpoint", stack);
      }
    }
  }

  ///测试端点连通性
  Future<bool> _testEndPointConnection(EndPoint endpoint) async {
    Socket? socket;
    try {
      socket = await Socket.connect(endpoint.host, endpoint.port, timeout: 2.s);
      await socket.close();
      return true;
    } catch (_) {
      return false;
    } finally {
      socket?.destroy();
    }
  }

  ///加密连接
  Future<void> _connect({
    required bool isDirect,
    EndPoint? endPoint,
    Socket? socket,
    String? targetDevId,
  }) async {
    SecureSocketClient client;
    if (endPoint == null && socket == null) {
      throw ArgumentError('Either endPoint or socket must be provided, but both are null.');
    }
    if (endPoint != null && socket != null) {
      throw ArgumentError('Only one of endPoint or socket can be provided, but both were given.');
    }
    if (endPoint != null) {
      client = await SecureSocketClient.createFromEndPoint(
        endPoint: endPoint,
        onMessage: _onMessage,
        onDone: _onDone,
        onError: _onError,
        onDeviceForget: _onForgetDevMessage,
        connectionMode: isDirect ? ConnectionMode.direct : ConnectionMode.forward,
        selfDevId: appConfig.devInfo.guid,
        targetDevId: targetDevId,
        timeout: 2.s,
      );
    } else if (socket != null) {
      client = await SecureSocketClient.createFromSocket(
        socket: socket,
        onMessage: _onMessage,
        onDone: _onDone,
        onError: _onError,
        onDeviceForget: _onForgetDevMessage,
        connectionMode: isDirect ? ConnectionMode.direct : ConnectionMode.forward,
        selfDevId: appConfig.devInfo.guid,
        targetDevId: targetDevId,
        timeout: 2.s,
      );
    } else {
      throw '';
    }
    await _onClientConnected(client);
  }

  //连接中转服务器
  Future<void> connectForwardServer() async {
    if (!(_forwardClient?.closed ?? true)) {
      //已经连接且未关闭，无需重连
      return;
    }
    final forwardConfig = appConfig.forwardServer;
    if (forwardConfig == null) {
      return;
    }
    if (appConfig.forwardWay != ForwardWay.server) {
      return;
    }
    try {
      _forwardClient = await ForwardSocketClient.connect(
        key: appConfig.forwardServer?.key,
        endPoint: EndPoint(forwardConfig.host, forwardConfig.port),
        onMessage: _onForwardClientMessage,
        onError: _onForwardClientError,
        onDone: _onForwardClientDone,
      );
      final version = _forwardClient?.serverInfo?.version ?? "";
      appConfig.forwardServerVersion.value = version;
    } catch (err, stack) {
      Log.error(tag, err, stack);
    }
  }

  ///重连设备
  Future<void> _reconnect(String devId) async {
    if (_reconnectingDevIds.contains(devId)) {
      Log.warn(tag, "Device $devId is reconnecting");
      return;
    }
    final device = await dbService.deviceDao.getById(devId, appConfig.userId);
    if (device == null) {
      Log.warn(tag, "Device $devId not found in db");
      return;
    }
    final devInfo = DevInfo.fromDevice(device);
    var endTime = DateTime.now().add(const Duration(minutes: 3));
    final internalAddress = device.internalAddress;
    //三分钟内持续尝试
    while (DateTime.now().isBefore(endTime)) {
      final skt = _devSockets[devId];
      if (skt != null && !skt.closed) {
        Log.debug(tag, "重连成功 ${device.name}(${skt.host}:${skt.port})");
        //已经成功连接，停止重连
        _reconnectingDevIds.remove(devId);
        return;
      }
      Log.debug(tag, "尝试重连 ${device.name}");
      try {
        Log.debug(tag, "${device.name} internalAddress = $internalAddress");
        var internalAvailable = false;

        //region 尝试内网重连

        if (internalAddress != null) {
          final [ip, portStr] = internalAddress.split(":");
          Socket? skt;
          try {
            //先尝试连接内网地址
            final port = portStr.toInt();
            skt = await Socket.connect(ip, port, timeout: 2.s);
            internalAvailable = true;
            skt.close();
            skt.destroy();
            //加入连接队列
            pendingConnectionQueue.add(DeviceEndPoint(devInfo, ip, port));
          } finally {
            skt?.destroy();
          }
        }

        //endregion

        //region 尝试中转重连

        if (!internalAvailable) {}

        //todo

        //endregion
      } catch (err) {
        Log.warn(tag, "attempt reconnect error: $err");
      }

      //延迟3s
      await Future.delayed(3.s);
    }
    Log.debug(tag, "重连失败 ${device.name}(${device.guid})");
  }

  ///客户端连接成功建立
  Future<void> _onClientConnected(SecureSocketClient client) async {
    final dev = client.devInfo;
    final oldClient = _devSockets[dev.guid];
    //检查在线状态
    final isOnline = await oldClient?.testOnline() ?? false;
    if (isOnline) {
      //如果旧连接仍然在线，终止当前连接
      await client.close();
      return;
    }
    //不在线则强制关闭旧连接
    _devSockets.remove(dev.guid);
    await oldClient?.close();
    //将当前连接添加到本地缓存
    _devSockets[dev.guid] = client;
    TransportProtocol protocol = TransportProtocol.direct;
    if (client.isForwardMode) {
      protocol = TransportProtocol.server;
    }
    //添加到注册服务
    _registry.addDevice(client.devInfo, protocol);
    //通知观察者设备连接成功
    _notifyDeviceConnected(client, protocol);
  }

  Future<void> _onDone(SecureSocketClient client) async {
    final devId = client.devInfo.guid;
    final cachedClient = _devSockets[devId];
    if (!identical(cachedClient, client)) {
      //当前连接与缓存的不一致则直接结束
      Log.debug(tag, "_onDone cachedClient(${cachedClient?.hashCode}) != closed client(${client.hashCode})");
      return;
    }
    _devSockets.remove(devId);
    //再次手动关闭，否则可能在某些特殊环境下出现 TIME_WAIT 导致端口不释放
    await client.close();
    final isClosedByUser = client.isClosedByUser;
    //从注册服务移除
    _registry.removeDevice(devId);
    //通知观察者设备连接断开
    _notifyDeviceDisconnected(client);
    if (!isClosedByUser) {
      //非主动关闭，进入重试
      _reconnect(devId);
    }
  }

  void _onError(SecureSocketClient client, Object e, StackTrace trace) {
    Log.error(tag, "client error: $e, devName = ${client.devInfo.name}", trace);
  }

  ///忘记设备
  void _onForgetDevMessage(SecureSocketClient client) {
    final dev = client.devInfo;
    Log.debug(tag, "${dev.name} forget");
    for (var listener in _devAliveListeners) {
      try {
        listener.onForget(dev, 0);
      } catch (e, t) {
        Log.debug(tag, "$e $t");
      }
    }
  }

  ///通知观察者设备配对成功
  void _notifyDevicePaired(SecureSocketClient client, bool paired) {
    final address = "${client.host}:${client.port}";
    for (var listener in _devAliveListeners) {
      try {
        listener.onPaired(client.devInfo, 0, paired, address);
      } catch (err, stack) {
        Log.error(tag, err, stack);
      }
    }
  }

  ///通知观察者设备取消配对
  void _notifyDeviceCancelPairing(SecureSocketClient client) {
    for (var listener in _devAliveListeners) {
      try {
        listener.onCancelPairing(client.devInfo);
      } catch (err, stack) {
        Log.error(tag, err, stack);
      }
    }
  }

  ///通知观察者设备连接成功
  void _notifyDeviceConnected(SecureSocketClient client, TransportProtocol protocol) {
    for (var listener in _devAliveListeners) {
      try {
        listener.onConnected(client.devInfo, client.minVersion, client.version, protocol);
      } catch (err, stack) {
        Log.error(tag, err, stack);
      }
    }
  }

  ///通知观察者设备连接断开
  void _notifyDeviceDisconnected(SecureSocketClient client) {
    for (var listener in _devAliveListeners) {
      try {
        listener.onDisconnected(client.devInfo.guid);
      } catch (err, stack) {
        Log.error(tag, err, stack);
      }
    }
  }

  ///region 消息接收与处理

  ///region 中转连接处理

  ///中转连接收到消息
  Future<void> _onForwardClientMessage(
    ForwardSocketClient self,
    ForwardMsgType msgType,
    Map<String, dynamic> data,
  ) async {
    return switch (msgType) {
      ForwardMsgType.fileSyncNotAllowed => _onForwardMessageFileSyncNotAllowed(self, data),
      ForwardMsgType.requestConnect => _onForwardMessageRequestConnect(self, data),
      ForwardMsgType.sendFile => _onForwardMessageSendFile(self, data),
      ForwardMsgType.fileReceiverConnected => _onForwardMessageFileReceiverConnected(self, data),
      _ => throw UnimplementedError(),
    };
  }

  ///region 中转连接消息处理

  ///中转不允许文件发送
  Future<void> _onForwardMessageFileSyncNotAllowed(
    ForwardSocketClient self,
    Map<String, dynamic> data,
  ) async {
    Global.showTipsDialog(
      context: Get.context!,
      text: TranslationKey.forwardServerNotAllowedSendFile.tr,
      title: TranslationKey.sendFailed.tr,
    );
  }

  ///中转连接检测
  Future<void> _onForwardMessageCheck(
    ForwardSocketClient self,
    Map<String, dynamic> data,
  ) async {
    //todo
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
      final version = data["version"]?.toString();
      appConfig.forwardServerVersion.value = version ?? "";
      if (ForwardSocketClient.lessThan114(version)) {
        final dialog = await Global.showTipsDialog(
          context: Get.context!,
          text: TranslationKey.forwardServer114VersionTip.tr,
        );
        if (dialog != null) {
          NotifyUtil.notify(
            content: TranslationKey.forwardServer114VersionTip.tr,
            key: TranslationKey.forwardServer114VersionTip.name,
          );
        }
      }
      return;
    }
    disableForwardServerAfterDelay();
    Global.showTipsDialog(
      context: Get.context!,
      text: result,
      title: TranslationKey.forwardServerConnectFailed.tr,
    );
  }

  ///中转设备请求连接
  Future<void> _onForwardMessageRequestConnect(
    ForwardSocketClient self,
    Map<String, dynamic> data,
  ) async {}

  ///中转文件发送
  Future<void> _onForwardMessageSendFile(
    ForwardSocketClient self,
    Map<String, dynamic> data,
  ) async {}

  ///中转文件接收者连接消息
  Future<void> _onForwardMessageFileReceiverConnected(
    ForwardSocketClient self,
    Map<String, dynamic> data,
  ) async {}

  ///endregion

  ///中转连接关闭
  Future<void> _onForwardClientDone(ForwardSocketClient self) async {}

  ///中转连接错误
  Future<void> _onForwardClientError(
    ForwardSocketClient self,
    Object error,
    StackTrace trace,
  ) async {}

  ///endregion

  ///region 直连连接处理

  ///消息接收
  Future<void> _onMessage(SecureSocketClient client, MessageData msg) {
    final sender = msg.send;
    final key = msg.key;
    final data = msg.data;
    Log.debug(tag, "onMessage ${sender.name} $key");
    return switch (key) {
      MsgType.sync => _onSyncMessage(client, msg),
      MsgType.ackSync => _onSyncMessage(client, msg),
      MsgType.missingData => _onMissingDataMessage(client, msg),
      MsgType.reqMissingData => _onReqMissingDataMessage(client, sender, data),
      MsgType.reqAppInfo => _onReqAppInfoMessage(client, sender, data),
      MsgType.appInfo => _onAppInfoMessage(client, sender, data),
      MsgType.reqPairing => _onReqPairingMessage(client, sender, data),
      MsgType.pairing => _onPairingMessage(client, sender, data),
      MsgType.paired => _onPairedMessage(client, sender, data),
      MsgType.cancelPairing => _onCancelPairingMessage(client, sender, data),
      MsgType.file => _onFileMessage(client, sender, data),
      _ => throw UnimplementedError(),
    };
  }

  ///region 直连消息处理

  ///收到同步消息
  Future<void> _onSyncMessage(SecureSocketClient client, MessageData msg) async {
    Module module = Module.getValue(msg.data["module"]);
    Log.debug(tag, "module ${module.moduleName}");
    //筛选某个模块的同步处理器
    var lst = getListeners(module);
    for (var listener in lst) {
      switch (msg.key) {
        case MsgType.sync:
        case MsgType.missingData:
          dbService.execSequentially(() => listener.onSync(msg));
          break;
        case MsgType.ackSync:
          dbService.execSequentially(() => listener.ackSync(msg));
          break;
        default:
          break;
      }
    }
  }

  ///收到请求配对消息
  Future<void> _onReqPairingMessage(
    SecureSocketClient client,
    DevInfo sender,
    Map<String, dynamic> data,
  ) async {
    final random = Random();
    int code = 100000 + random.nextInt(900000);
    DevPairingHandler.addCode(sender.guid, CryptoUtil.toMD5(code));
    //发送通知
    final notifyId = await NotifyUtil.notify(
      content: "${TranslationKey.newParingRequest.tr}: $code",
      key: "dev-pairing-${sender.guid}",
    );
    _pairingNotifyIds[sender.guid] = notifyId;
    if (_pairingDevIds.contains(sender.guid)) {
      Get.back();
    }
    _pairingDevIds.add(sender.guid);
    final dialogWidget = AlertDialog(
      title: Text(TranslationKey.paringRequest.tr),
      content: IntrinsicHeight(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(TranslationKey.pairingCodeDialogContent.trParams({"devName": sender.name})),
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
            cancelPairing(sender);
          },
          child: Text(TranslationKey.cancelCurrentPairing.tr),
        ),
      ],
    );
    Global.showDialog(Get.context!, dialogWidget);
  }

  ///取消配对
  void cancelPairing(DevInfo dev) {
    final devId = dev.guid;
    if (!_pairingDevIds.contains(devId)) return;
    DevPairingHandler.removeCode(devId);
    Get.back();
    dev.sendData(MsgType.cancelPairing, {}, false);
    final notifyId = _pairingNotifyIds[devId];
    if (notifyId != null) {
      NotifyUtil.cancel("dev-pairing-$devId", notifyId);
    }
    _pairingDevIds.remove(devId);
    _pairingNotifyIds.remove(devId);
  }

  ///收到配对消息
  Future<void> _onPairingMessage(
    SecureSocketClient client,
    DevInfo sender,
    Map<String, dynamic> data,
  ) async {
    String code = data["code"];
    //验证配对码
    var verify = DevPairingHandler.verify(sender.guid, code);
    _notifyDevicePaired(client, verify);
    //返回配对结果
    MessageData msg = MessageData(
      userId: appConfig.userId,
      send: appConfig.devInfo,
      key: MsgType.paired,
      data: {"result": verify},
      recv: null,
    );
    await client.send(msg.toJson());
  }

  ///收到取消配对消息
  Future<void> _onCancelPairingMessage(
    SecureSocketClient client,
    DevInfo sender,
    Map<String, dynamic> data,
  ) async {
    DevPairingHandler.removeCode(sender.guid);
    final pairing = _pairingDevIds.contains(sender.guid);
    if (pairing) {
      Get.back();
    }
    Log.debug(tag, "${sender.name} cancelPairing");
    final notifyId = _pairingNotifyIds[sender.guid];
    if (notifyId != null) {
      NotifyUtil.cancel("dev-pairing-${sender.guid}", notifyId);
    }
    _pairingDevIds.remove(sender.guid);
    _pairingNotifyIds.remove(sender.guid);
    _notifyDeviceCancelPairing(client);
  }

  ///收到已配对结果
  Future<void> _onPairedMessage(
    SecureSocketClient client,
    DevInfo sender,
    Map<String, dynamic> data,
  ) async {
    bool result = data["result"];
    final pairing = _pairingDevIds.contains(sender.guid);
    _pairingDevIds.remove(sender.guid);
    _pairingNotifyIds.remove(sender.guid);
    if (pairing) {
      Get.back();
    }
    _notifyDevicePaired(client, result);
  }

  ///收到请求缺失数据消息
  Future<void> _onReqMissingDataMessage(
    SecureSocketClient client,
    DevInfo sender,
    Map<String, dynamic> data,
  ) async {
    var syncedAppIds = ((data["appIds"] ?? []) as List<dynamic>).cast<String>();
    MissingDataSyncHandler.sendMissingData(sender, appConfig.device.guid, syncedAppIds);
  }

  ///收到缺失数据
  Future<void> _onMissingDataMessage(SecureSocketClient client, MessageData msg) async {
    var copyMsg = MessageData.fromJson(msg.toJson());
    var data = msg.data["data"] as Map<dynamic, dynamic>;
    copyMsg.data = data.cast<String, dynamic>();
    final total = msg.data["total"];
    int seq = msg.data["seq"];
    final syncProgressService = Get.find<HistorySyncProgressService>();
    syncProgressService.addProgress(copyMsg.send.guid, copyMsg.data, seq, total, false);
    await _onSyncMessage(client, copyMsg);
  }

  ///收到请求app信息消息
  Future<void> _onReqAppInfoMessage(
    SecureSocketClient client,
    DevInfo sender,
    Map<String, dynamic> data,
  ) async {
    final appId = data["appId"];
    final sourceService = Get.find<ClipboardSourceService>();
    final appInfo = sourceService.appInfos.firstWhereOrNull((item) => item.devId == appConfig.device.guid && appId == item.appId);
    if (appInfo == null) {
      return;
    }
    MessageData msg = MessageData(
      userId: appConfig.userId,
      send: appConfig.devInfo,
      key: MsgType.appInfo,
      data: appInfo.toJson(),
      recv: null,
    );
    await client.send(msg.toJson());
  }

  ///收到app信息
  Future<void> _onAppInfoMessage(
    SecureSocketClient client,
    DevInfo sender,
    Map<String, dynamic> data,
  ) async {
    final appInfo = AppInfo.fromJson(data);
    final sourceService = Get.find<ClipboardSourceService>();
    await sourceService.addOrUpdate(appInfo);
  }

  ///收到文件同步消息
  Future<void> _onFileMessage(
    SecureSocketClient client,
    DevInfo sender,
    Map<String, dynamic> data,
  ) async {
    String ip = client.host;
    int port = data["port"];
    int size = data["size"];
    String fileName = data["fileName"];
    int fileId = data["fileId"];
    try {
      await FileSyncHandler.receiveFile(
        ip: ip,
        port: port,
        size: size,
        fileName: fileName,
        devId: sender.guid,
        userId: 0,
        fileId: fileId,
        context: Get.context!,
      );
    } catch (err, stack) {
      Log.debug(
        tag,
        "receive file failed. ip:$ip, port: $port, size: $size, fileName: $fileName. "
        "$err $stack",
      );
    }
  }

  ///endregion

  ///endregion

  ///endregion

  ///设备发现心跳测试
  void startHeartbeatTest() {
    stopHeartbeatTest();
    _heartbeatTimer = Timer.periodic(appConfig.heartbeatInterval.s, (_) async {
      var sockets = _devSockets.values.toList();
      for (var skt in sockets) {
        final result = await skt.testOnline();
        if (!result) {
          Log.warn(tag, "dev ${skt.devInfo.name} offline");
          await skt.close();
        }
      }
    });
  }

  ///停止心跳测试
  void stopHeartbeatTest() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  ///屏幕打开
  @override
  void onScreenOpened() {
    Log.debug(tag, "屏幕打开");
  }

  ///屏幕关闭
  @override
  void onScreenClosed() {
    Log.debug(tag, "屏幕关闭");
  }

  @override
  Future<void> sendData(
    DevInfo? dev,
    MsgType key,
    Map<String, dynamic> data, [
    bool onlyPaired = true,
  ]) async {
    Iterable<SecureSocketClient> list = [];
    final appMinVersion = appConfig.minVersion;
    //向所有设备发送消息
    if (dev == null) {
      list = onlyPaired ? _devSockets.values.where((client) => client.isPaired) : _devSockets.values;
      //筛选兼容版本的设备
      list = list.where((dev) => dev.version >= appMinVersion);
    } else {
      //向指定设备发送消息
      SecureSocketClient? skt = _devSockets[dev.guid];
      if (skt == null) {
        Log.debug(tag, "${dev.name} 设备未连接，发送失败");
        return;
      }
      if (skt.version < appMinVersion) {
        Log.debug(tag, "${dev.name} 与当前设备版本不兼容");
        return;
      }
      list = [skt];
    }
    //批量发送
    for (var skt in list) {
      MessageData msg = MessageData(
        userId: appConfig.userId,
        send: appConfig.devInfo,
        key: key,
        data: data,
        recv: null,
      );
      await skt.send(msg.toJson());
    }
  }

  /// 发送广播消息
  void sendMulticastMsg(MsgType key, Map<String, dynamic> data) {
    MessageData msg = MessageData(
      userId: 0,
      send: appConfig.devInfo,
      key: key,
      data: data,
      recv: null,
    );
    try {
      var b64Data = CryptoUtil.base64EncodeStr("${msg.toJsonStr()}\n");
      for (var multicast in _multicasts) {
        multicast.send(
          utf8.encode(b64Data),
          InternetAddress(Constants.multicastGroup),
          appConfig.port,
        );
        multicast.close();
      }
    } catch (e, stacktrace) {
      Log.debug(tag, "$e $stacktrace");
    }
  }
}
