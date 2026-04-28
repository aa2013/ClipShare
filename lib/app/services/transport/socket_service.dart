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
import 'package:clipshare/app/data/repository/entity/tables/device.dart';
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
import 'package:clipshare/app/modules/device_module/device_controller.dart';
import 'package:clipshare/app/services/clipboard_source_service.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/services/device_service.dart';
import 'package:clipshare/app/services/history_sync_progress_service.dart';
import 'package:clipshare/app/services/transport/connection_registry_service.dart';
import 'package:clipshare/app/services/tray_service.dart';
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
import 'package:wakelock_plus/wakelock_plus.dart';

typedef VoidFutureFunction = Future<void> Function();

///中转重连数据：
///[discovery] 表示是否进行设备发现以及异步连接结果返回
///[result] 异步结果为 true 表示无需再重连（成功或者不满足重连条件），为 false 表示还需继续重连（满足中转连接条件但是连接失败）
typedef _ForwardReconnectData = (bool discovery, Completer<bool> result);

class _ConnectionEvent {
  final DeviceEndPoint? endPoint;
  final Socket? socket;
  final Completer<bool>? completer;

  _ConnectionEvent({
    this.endPoint,
    this.socket,
    this.completer,
  }) {
    final isEndPointNull = endPoint == null;
    final isSocketNull = socket == null;
    if (!(isEndPointNull ^ isSocketNull)) {
      throw Exception('EndPoint and Socket must have exactly one non-null');
    }
  }
  @override
  String toString() {
    return "endPoint = $endPoint, socket = ${socket?.hashCode}, completer ${completer != null}";
  }
}
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

  bool get discovering => _discovering;

  //屏幕是否打开
  bool _screenOpened = true;

  //自动关闭连接定时器
  Timer? _autoCloseConnTimer;

  //设备发现控制令牌
  CancelTokenSource _discoveryTokenSource = CancelTokenSource();

  //设备待连接队列
  final _deviceConnectionQueue = StreamController<_ConnectionEvent>();

  // 某设备的Socket连接，devId => DevSocket
  final Map<String, SecureSocketClient> _devSockets = {};

  //重连中的设备id
  final Set<String> _reconnectingDevIds = {};

  //配对通知 id, devId => notifyId
  final _pairingNotifyIds = <String, int?>{};

  //配对中的设备id
  final _pairingDevIds = <String>{};

  //中转连接客户端
  ForwardSocketClient? _forwardClient;

  //中转客户端待连接队列
  final _forwardConnectionQueue = StreamController<_ForwardReconnectData>();

  //中转发送的文件
  final Map<int, FileSyncHandler> _forwardFiles = {};

  //中转已连接
  bool get forwardServerConnected => _forwardClient != null;

  //region dev registry
  final DeviceConnectionRegistry _registry;

  List<DevAliveListener> get _devAliveListeners => _registry.devAliveListeners;

  List<DiscoverListener> get _discoverListeners => _registry.discoverListeners;

  List<ForwardStatusListener> get _forwardStatusListener => _registry.forwardStatusListener;

  //endregion

  //正在通知的设备，用于防抖，devId => (notifyId, int) 断开连接-1，新连接+1
  //时常为 2s，如果 2s 内，该 map 有 key 且 id 仍然为发起通知时创建的 id 则允许通知，否则取消通知
  final _devNotifyMap = <String, int>{};
  final _devNotifyTimerMap = <String, Timer>{};

  //通知防抖时长
  static final _debounceTime = 1500.ms;

  SocketService(this._registry);

  Future<SocketService> init() async {
    if (_isInit) throw Exception("已初始化");
    ScreenOpenedListener.inst.register(this);
    //启动服务端监听连接，广播监听，设备发现
    _runSocketServer();
    _runDeviceConnectTask();
    _runForwardServerConnectTask();
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
        Log.debug(tag, "receive from server");
        _deviceConnectionQueue.add(_ConnectionEvent(socket: socket));
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
          Log.debug(tag, "receive from broadcast $ip");
          _deviceConnectionQueue.add(_ConnectionEvent(endPoint: DeviceEndPoint(dev, ip, port)));
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
    bool scan = false,
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
    appConfig.deviceDiscoveryStatus.value = TranslationKey.deviceDiscoveryStatusReady.tr;
    //尝试连接中转服务器，此处只尝试一次，若失败则持续重试
    final connected = await connectForwardServer(false, false);
    if (!connected) {
      //此处不要等待，会持续重试
      connectForwardServer(false, true);
    }

    final token = _discoveryTokenSource.token;
    final onlyForwardMode = appConfig.onlyForwardMode;
    //发现已配对设备
    if (token.isCanceled) {
      onDiscoveryStopped();
      return;
    }
    appConfig.deviceDiscoveryStatus.value = TranslationKey.deviceDiscoveryStatusViaPaired.tr;
    Log.debug(tag, appConfig.deviceDiscoveryStatus.value);
    final List<VoidFutureFunction> pairedDiscoveryTasks = _pairedDiscovering();
    await ParallelTask(
      tasks: pairedDiscoveryTasks,
      maxParallelCnt: maxParallelCnt,
      token: token,
    ).run();

    if (!scan) {
      onDiscoveryStopped();
      return;
    }
    //广播发现
    if (token.isCanceled) {
      onDiscoveryStopped();
      return;
    }
    appConfig.deviceDiscoveryStatus.value = TranslationKey.deviceDiscoveryStatusViaBroadcast.tr;
    Log.debug(tag, appConfig.deviceDiscoveryStatus.value);
    final isMobileNetwork = appConfig.currentNetWorkType.value == ConnectivityResult.mobile && PlatformExt.isMobile;
    final List<VoidFutureFunction> multicastDiscoveryTasks = isMobileNetwork || onlyForwardMode ? [] : _multicastDiscovering();
    await ParallelTask(
      tasks: multicastDiscoveryTasks,
      maxParallelCnt: 1,
      token: token,
    ).run();

    //子网扫描
    if (token.isCanceled) {
      onDiscoveryStopped();
      return;
    }
    appConfig.deviceDiscoveryStatus.value = TranslationKey.deviceDiscoveryStatusViaScan.tr;
    Log.debug(tag, appConfig.deviceDiscoveryStatus.value);
    final List<VoidFutureFunction> subnetDiscoveryTasks = isMobileNetwork || appConfig.onlyForwardMode ? [] : await _subNetDiscovering(manual);
    await ParallelTask(
      tasks: subnetDiscoveryTasks,
      maxParallelCnt: maxParallelCnt,
      token: token,
    ).run();
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
  Future<void> restartDiscoveryDevices({bool manual = false, bool scan = false}) async {
    await stopDiscoveryDevices(true);
    await startDiscoveryDevices(manual: manual, scan: scan);
  }

  ///发现已连接设备
  List<VoidFutureFunction> _pairedDiscovering() {
    final deviceService = Get.find<DeviceService>();
    final pairedList = deviceService.pairedList;
    final List<VoidFutureFunction> list = [];
    for (var device in pairedList) {
      list.add(() => reconnectOnce(device.guid));
    }
    return list;
  }

  ///广播发现
  List<VoidFutureFunction> _multicastDiscovering() {
    List<VoidFutureFunction> tasks = [];
    for (var ms in const [100, 500, 2000, 5000]) {
      tasks.add(
        () => Future.delayed(ms.ms, () {
          // 广播本机socket信息
          Map<String, dynamic> map = {"port": _server.port};
          _sendMulticastMsg(MsgType.broadcastInfo, map);
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
    var interfaces = (await NetworkInterface.list()).where(
      (itf) => !appConfig.noDiscoveryIfs.contains(itf.name),
    );
    var expendAddress = interfaces.map((itf) => itf.addresses).expand((ip) => ip);
    var ips = expendAddress.where((ip) => ip.type == InternetAddressType.IPv4).map((address) => address.address).toList();
    for (var ip in ips) {
      //生成所有 ip
      final ipList = List.generate(
        255,
        (i) => '${ip.split('.').take(3).join('.')}.$i',
      ).where((genIp) => genIp != ip).toList();
      //对每个ip尝试连接
      for (var genIp in ipList) {
        tasks.add(() async {
          try {
            final socket = await Socket.connect(genIp, appConfig.port, timeout: 2.s);
            _deviceConnectionQueue.add(_ConnectionEvent(socket: socket));
          } catch (_) {}
        });
      }
    }
    return tasks;
  }

  ///endregion

  ///region 设备连接与重连

  ///region 直连设备

  ///设备连接任务
  Future<void> _runDeviceConnectTask() async {
    await for (final event in _deviceConnectionQueue.stream) {
      final completer = event.completer;
      try {
        final endPoint = event.endPoint;
        final socket = event.socket;
        late final SecureSocketClient newClient;
        final isSender = endPoint != null;
        late final String targetDevId;
        if(endPoint != null){
          final devInfo = endPoint.devInfo;
          final devId = devInfo.guid;
          targetDevId = devId;
          final forwardEndPoint = appConfig.forwardServer?.endPoint;
          final isDirect = endPoint != forwardEndPoint;
          newClient = await _connect(
            endPoint: endPoint,
            isDirect: isDirect,
            targetDevId: isDirect ? null : devId,
          );
        }
        else if(socket != null){
          newClient = await _connect(
            socket: socket,
            isDirect: true,
          );
          targetDevId = newClient.devInfo.guid;
        }else{
          throw 'Not Supported endPoint = null and socket = null';
        }
        //连接成功，进行连接裁决
        final client = await _handleNewConnection(
          targetDevId,
          newClient,
          isSender,
        );
        if(identical(client, newClient)) {
          await _onClientConnected(client);
        }
      } catch (err, stack) {
        completer?.complete(false);
        Log.error(tag, "error:$err, event:$event", stack);
      }
    }
  }

  ///连接裁决
  bool _shouldKeepNew(bool isSender, String targetId) {
    final myHash = appConfig.devInfo.guid.hash64;
    final targetHash = targetId.hash64;
    if (myHash > targetHash) {
      return isSender; // 我赢 → 用主动
    } else {
      return !isSender; // 我输 → 用被动
    }
  }

  ///连接裁决，返回值表示是否发起连接通知
  Future<SecureSocketClient> _handleNewConnection(
      String devId,
      SecureSocketClient newSkt,
      bool isSender,
  ) async {
    final oldSkt = _devSockets[devId];
    //没旧连接，直接用
    if (oldSkt == null) {
      _devSockets[devId] = newSkt;
      return newSkt;
    }

    bool oldValid = false;

    if (!oldSkt.closed) {
      oldValid = await oldSkt.testOnline();
    }

    //旧连接死了，直接替换
    if (!oldValid) {
      await oldSkt.sendData(MsgType.disConnect, {});
      await oldSkt.close(true);
      _devSockets[devId] = newSkt;
      return newSkt;
    }

    //两个都活着 → 裁决
    final keepNew = _shouldKeepNew(isSender, devId);

    if (keepNew) {
      await oldSkt.sendData(MsgType.disConnect, {});
      await oldSkt.close(true);
      _devSockets[devId] = newSkt;
      return newSkt;
    } else {
      await newSkt.sendData(MsgType.disConnect, {});
      await newSkt.close(true);
      return oldSkt;
    }
  }

  ///加密连接
  Future<SecureSocketClient> _connect({
    required bool isDirect,
    EndPoint? endPoint,
    Socket? socket,
    String? targetDevId,
  }) async {
    if (endPoint == null && socket == null) {
      throw ArgumentError(
        'Either endPoint or socket must be provided, but both are null.',
      );
    }
    if (endPoint != null && socket != null) {
      throw ArgumentError(
        'Only one of endPoint or socket can be provided, but both were given.',
      );
    }
    if (endPoint != null) {
      return await SecureSocketClient.createFromEndPoint(
        endPoint: endPoint,
        onMessage: _onMessage,
        onDone: _onDone,
        onError: _onError,
        onDeviceForget: (client) async {
          await _onDeviceForget(client.devInfo);
        },
        connectionMode: isDirect ? ConnectionMode.direct : ConnectionMode.forward,
        selfDevId: appConfig.devInfo.guid,
        targetDevId: targetDevId,
        timeout: 2.s,
      );
    } else if (socket != null) {
      Log.debug(tag, socket.remoteAddress.address);
      return await SecureSocketClient.createFromSocket(
        socket: socket,
        onMessage: _onMessage,
        onDone: _onDone,
        onError: _onError,
        onDeviceForget: (client) async {
          await _onDeviceForget(client.devInfo);
        },
        connectionMode: isDirect ? ConnectionMode.direct : ConnectionMode.forward,
        selfDevId: appConfig.devInfo.guid,
        targetDevId: targetDevId,
        timeout: 2.s,
      );
    } else {
      throw 'not supported';
    }
  }

  ///连接设备
  Future<bool> connect(EndPoint endPoint, [String? targetDevId]) async {
    try {
      bool isDirect = true;
      if (endPoint.host == _forwardClient?.host) {
        isDirect = false;
        if (targetDevId == null) {
          return false;
        }
      }
      final client = await SecureSocketClient.createFromEndPoint(
        endPoint: endPoint,
        onMessage: (_, _) {},
        onDone: (_) {},
        onError: (_, _, _) {},
        onDeviceForget: (_) {},
        connectionMode: isDirect ? ConnectionMode.direct : ConnectionMode.forward,
        selfDevId: appConfig.devInfo.guid,
        targetDevId: targetDevId,
        timeout: 2.s,
      );
      final devInfo = client.devInfo;
      await client.close(true);
      final devEndPoint = DeviceEndPoint(devInfo, endPoint.host, endPoint.port);
      final completer = Completer<bool>();
      _deviceConnectionQueue.add(_ConnectionEvent(endPoint: devEndPoint, completer: completer));
      return completer.future.timeout(3.s);
    } catch (err, stack) {
      Log.error(tag, err, stack);
      return false;
    }
  }

  ///断开设备连接
  Future<void> disconnectDevice(String devId) async {
    final socket = _devSockets[devId];
    if (socket == null) {
      return;
    }
    await socket.sendData(MsgType.disConnect, {});
    await socket.close(true);
    _notifyDeviceDisconnected(socket);
  }

  ///断开所有连接
  Future<void> disConnectAllConnections([bool onlyNotPaired = false]) async {
    await disConnectForwardServer();
    for (var client in _devSockets.values.toList()) {
      if (onlyNotPaired && client.isPaired) {
        continue;
      }
      await disconnectDevice(client.devInfo.guid);
    }
  }

  ///重连设备
  ///[once] 为 true 表示只重连一次，否则在指定时间内持续重试
  Future<bool> _reconnect(String devId, [bool once = false]) async {
    if (_reconnectingDevIds.contains(devId)) {
      Log.warn(tag, "Device $devId is reconnecting");
      return false;
    }
    _reconnectingDevIds.add(devId);
    try {
      final device = await dbService.deviceDao.getById(devId, appConfig.userId);
      if (device == null) {
        Log.warn(tag, "Device $devId not found in db");
        return false;
      }
      final devInfo = DevInfo.fromDevice(device);
      final startTime = DateTime.now();
      var endTime = startTime.add(const Duration(minutes: 3));
      final internalAddress = device.internalAddress;
      var retryCount = 0;
      //三分钟内持续尝试
      while (true) {
        //只重连一次且已经重连了一次
        if (once && retryCount == 1) {
          return false;
        }
        final skt = _devSockets[devId];
        if (skt != null && !skt.closed) {
          if (retryCount > 0) {
            final timeOffset = DateTime.now().difference(startTime).inSeconds;
            Log.debug(tag, "重连成功 ${device.name}(${skt.host}:${skt.port}), 共重试了 $retryCount 次, 耗时 $timeOffset s");
          }
          return true;
        }
        if (!DateTime.now().isBefore(endTime)) {
          //重连超时，重连操作结束后回来判断下重连是否成功再决定是否退出循环
          break;
        }
        retryCount++;
        Log.debug(tag, "尝试重连 ${device.name} 第 $retryCount 次");
        try {
          Log.debug(tag, "${device.name} internalAddress = $internalAddress");
          var internalAvailable = false;

          //region 尝试内网重连

          if (internalAddress != null && !appConfig.onlyForwardMode) {
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
              final completer = Completer<bool>();
              final devEndPoint = DeviceEndPoint(devInfo, ip, port);
              _deviceConnectionQueue.add(_ConnectionEvent(endPoint: devEndPoint, completer: completer));
              if (await completer.future) {
                continue;
              }
              internalAvailable = false;
            } catch (_) {
              //ignored
            } finally {
              skt?.destroy();
            }
          }

          //endregion

          //region 尝试中转重连

          if (!internalAvailable) {
            final forwardConfig = appConfig.forwardServer;
            if (forwardConfig != null && appConfig.enableForward) {
              final completer = Completer<bool>();
              final devEndPoint = DeviceEndPoint(
                devInfo,
                forwardConfig.host,
                forwardConfig.port,
              );
              _deviceConnectionQueue.add(_ConnectionEvent(endPoint: devEndPoint, completer: completer));
              if (await completer.future) {
                continue;
              }
            }
          }
          if (!once) {
            await Future.delayed(2.s);
          }

          //endregion
        } catch (err) {
          Log.warn(tag, "attempt reconnect error: $err");
        }
      }
      Log.debug(tag, "重连失败 ${device.name}(${device.guid})");
      return false;
    } finally {
      _reconnectingDevIds.remove(devId);
    }
  }

  ///重连设备（仅一次）
  Future<bool> reconnectOnce(String devId) async {
    return _reconnect(devId, true);
  }

  ///endregion 直连设备

  ///region 中转客户端连接

  ///中转客户端连接任务
  ///completer 异步结果为 true 表示无需再重连（连接成功 或 不满足条件）
  Future<void> _runForwardServerConnectTask() async {
    await for (var (discovery, completer) in _forwardConnectionQueue.stream) {
      try {
        if (await _forwardClient?.testOnline() ?? false) {
          //在线则忽略该次连接请求
          Log.debug(tag, 'Operation canceled: forwarding is online.');
          completer.complete(true);
          continue;
        }
        if (!appConfig.enableForward) {
          Log.debug(tag, 'Operation canceled: forwarding is disabled.');
          completer.complete(true);
          continue;
        }
        final forwardConfig = appConfig.forwardServer;
        if (forwardConfig == null) {
          Log.debug(tag, 'Operation canceled: forwardConfig is disabled.');
          completer.complete(true);
          continue;
        }
        if (appConfig.forwardWay != ForwardWay.server) {
          Log.debug(tag, 'Operation canceled: forwardWay = ${appConfig.forwardWay}');
          completer.complete(true);
          continue;
        }

        //屏幕关闭且 设置了自动断连
        if (!_screenOpened && appConfig.autoCloseConnAfterScreenOff && _autoCloseConnTimer == null) {
          Log.debug(tag, 'Operation canceled: screen closed and autoclose after screen off');
          completer.complete(true);
          return;
        }

        _notifyForwardConnectingStatus();
        _forwardClient = await ForwardSocketClient.connect(
          key: appConfig.forwardServer?.key,
          endPoint: EndPoint(forwardConfig.host, forwardConfig.port),
          onMessage: _onForwardClientMessage,
          onError: _onForwardClientError,
          onDone: _onForwardClientDone,
        );
        final version = _forwardClient?.serverInfo?.version ?? "";
        appConfig.forwardServerVersion.value = version;
        _notifyForwardConnectedStatus();
        completer.complete(true);
        //版本过低通知
        if (ForwardSocketClient.lessThan115(version)) {
          final dialog = await Global.showTipsDialog(
            context: Get.context!,
            text: TranslationKey.forwardServer115VersionTip.tr,
          );
          if (dialog != null) {
            NotifyUtil.notify(
              content: TranslationKey.forwardServer115VersionTip.tr,
              key: TranslationKey.forwardServer115VersionTip.name,
            );
          }
        }
        if (discovery) {
          final deviceController = Get.find<DeviceController>();
          final list = deviceController.offlineAndPairedList;
          for (var device in list) {
            final endPoint = DeviceEndPoint(DevInfo.fromDevice(device), forwardConfig.host, forwardConfig.port);
            final completer = Completer<bool>();
            _deviceConnectionQueue.add(_ConnectionEvent(endPoint: endPoint, completer: completer));
            await completer.future;
          }
        }
      } catch (err, stack) {
        Log.error(tag, err, stack);
        _notifyForwardDisconnectedStatus();
        completer.complete(false);
      }
    }
  }

  ///连接中转服务器，若失败且满足条件时将持续重试
  ///若需要重试，调用方不要进行异步等待
  Future<bool> connectForwardServer(bool discovery, bool allowRetry) async {
    final completer = Completer<bool>();
    _forwardConnectionQueue.add((discovery, completer));
    final shouldRetry = await completer.future;
    if (!shouldRetry && allowRetry) {
      //若失败，持续重连
      Log.debug(tag, "forward client will reconnect after 1s");
      await Future.delayed(1.s);
      await connectForwardServer(discovery, allowRetry);
    }
    return shouldRetry;
  }

  ///断开中转服务器连接
  Future<void> disConnectForwardServer() async {
    final client = _forwardClient;
    _forwardClient = null;
    await client?.close(true);
    //断开中转相关连接
    final list = _devSockets.values.where((v) => v.isForwardMode).toList();
    for (var client in list) {
      await client.close();
    }
  }

  ///region 中转连接状态事件

  ///通知观察者中转连接中
  void _notifyForwardConnectingStatus() {
    Log.debug(tag, "forward client connecting");
    for (var listener in _forwardStatusListener) {
      listener.onForwardServerConnecting();
    }
  }

  ///通知观察者中转已连接
  void _notifyForwardConnectedStatus() {
    Log.debug(tag, "forward client connected");
    for (var listener in _forwardStatusListener) {
      listener.onForwardServerConnected();
    }
  }

  ///通知观察者中转连接断开
  void _notifyForwardDisconnectedStatus() {
    Log.debug(tag, "forward client disconnected");
    for (var listener in _forwardStatusListener) {
      listener.onForwardServerDisconnected();
    }
  }

  ///endregion 中转连接状态事件

  ///endregion 中转客户端连接

  ///判断某设备是否使用中转连接
  bool isUseForward(String devId) {
    final client = _devSockets[devId];
    return client?.isForwardMode ?? false;
  }

  ///endregion 设备连接与重连

  ///设备连接成功建立
  Future<void> _onClientConnected(SecureSocketClient client) async {
    TransportProtocol protocol = TransportProtocol.direct;
    if (client.isForwardMode) {
      protocol = TransportProtocol.server;
    }
    //添加到注册服务
    _registry.addDevice(client.devInfo, protocol);
    final deviceService = Get.find<DeviceService>();
    final device = deviceService.getById(client.devInfo.guid);
    if (!identical(device, Device.unknown)) {
      if (device.isPaired != client.isPaired) {
        //双方配对状态不一致，执行忘记设备逻辑
        await deviceService.addOrUpdate(device..isPaired = false);
        notifyDeviceForget(client.devInfo);
      }
    }
    //更新连接地址
    final address = "${client.host}:${client.port}";
    if (client.isPaired) {
      if (!client.isForwardMode) {
        device.internalAddress = address;
      }
      device.address = address;
      await deviceService.addOrUpdate(device);
    }
    //通知观察者设备连接成功
    await _notifyDeviceConnected(client, protocol);
    if (client.isPaired) {
      //已配对，请求所有缺失数据
      reqMissingData(device.guid);
    }
  }

  ///设备连接关闭
  Future<void> _onDone(SecureSocketClient client) async {
    final devId = client.devInfo.guid;
    final cachedClient = _devSockets[devId];
    Log.debug(tag, "onDone ${client.devInfo.name}(${client.devInfo.guid})");
    if (!identical(cachedClient, client)) {
      //当前连接与缓存的不一致则直接结束
      Log.debug(
        tag,
        "_onDone cachedClient(${cachedClient?.hashCode}) != closed client(${client.hashCode})",
      );
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

  ///通知观察者忘记设备
  void notifyDeviceForget(DevInfo devInfo) {
    Log.debug(tag, "${devInfo.name} forget");
    for (var listener in _devAliveListeners) {
      try {
        listener.onForget(devInfo);
      } catch (e, t) {
        Log.debug(tag, "$e $t");
      }
    }
  }

  ///通知观察者设备配对成功
  void _notifyDevicePaired(SecureSocketClient client, bool paired) {
    final address = "${client.host}:${client.port}";
    print("paired address $address");
    for (var listener in _devAliveListeners) {
      try {
        listener.onPaired(client.devInfo, paired, address);
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

  ///设备连接后发起通知
  void _showDevConnectedNotification(String devId) {
    if (!appConfig.notifyOnDevConn) {
      return;
    }
    if (!(_devSockets[devId]?.isPaired ?? false)) {
      //未配对的不理会
      return;
    }
    _devNotifyMap.update(devId, (old) => old + 1, ifAbsent: () => 1);
    _devNotifyTimerMap.update(devId, (old) => old, ifAbsent: (){
      return Timer(_debounceTime, () async {
        try {
          if ((_devNotifyMap[devId] ?? 0) == 0) {
            return;
          }
          final devService = Get.find<DeviceService>();
          final notifyContent = TranslationKey.devConnectedNotifyContent
              .trParams({
            "devName": devService.getName(devId),
          });
          final key = "dev-conn-$devId";
          int? notifyId;
          if (!appConfig.useTrayFlashingForConnection) {
            await NotifyUtil.cancelAll(key);
            notifyId = await NotifyUtil.notify(
              key: key,
              content: notifyContent,
            );
          } else {
            final trayService = Get.find<TrayService>();
            trayService.flashTrayNormal(notifyContent);
          }
          if (notifyId != null) {
            Future.delayed(2.s, () {
              NotifyUtil.cancel(key, notifyId!);
            });
          }
        } finally {
          _devNotifyTimerMap.remove(devId);
        }
      });
    });
  }

  ///设备断开后发起通知
  void _showDevDisConnectNotification(String devId) {
    if (!appConfig.notifyOnDevDisconn) {
      return;
    }
    if (!(_devSockets[devId]?.isPaired ?? false)) {
      //未配对的不理会
      return;
    }
    _devNotifyMap.update(devId, (old) => old - 1, ifAbsent: () => -1);
    _devNotifyTimerMap.update(devId, (old) => old, ifAbsent: (){
      return Timer(_debounceTime, () async {
        try{
          if ((_devNotifyMap[devId] ?? 0) == 0) {
            return;
          }
          final devService = Get.find<DeviceService>();
          final notifyContent = TranslationKey.devDisconnectNotifyContent.trParams({
            "devName": devService.getName(devId),
          });
          final key = "dev-disconn-$devId";
          int? notifyId;
          if (!appConfig.useTrayFlashingForConnection) {
            await NotifyUtil.cancelAll(key);
            notifyId = await NotifyUtil.notify(
              key: key,
              content: notifyContent,
            );
          } else {
            final trayService = Get.find<TrayService>();
            trayService.flashTrayWarning(notifyContent);
          }
          if (notifyId != null) {
            Future.delayed(2.s, () {
              NotifyUtil.cancel(key, notifyId!);
            });
          }
        } finally {
          _devNotifyTimerMap.remove(devId);
        }
      });
    });
  }

  ///通知观察者设备连接成功
  Future<void> _notifyDeviceConnected(
    SecureSocketClient client,
    TransportProtocol protocol,
  ) async {
    for (var listener in _devAliveListeners) {
      try {
        await listener.onConnected(
          client.devInfo,
          client.minVersion,
          client.version,
          protocol,
        );
      } catch (err, stack) {
        Log.error(tag, err, stack);
      }
    }
    _showDevConnectedNotification(client.devInfo.guid);
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
    _showDevDisConnectNotification(client.devInfo.guid);
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
      ForwardMsgType.fileSyncNotAllowed => _onForwardMessageFileSyncNotAllowed(
        self,
        data,
      ),
      ForwardMsgType.requestConnect => _onForwardMessageRequestConnect(
        self,
        data,
      ),
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

  ///中转设备请求连接
  Future<void> _onForwardMessageRequestConnect(
    ForwardSocketClient self,
    Map<String, dynamic> data,
  ) async {
    final targetId = data["sender"] as String?;
    if (targetId == null) {
      Log.warn(tag, "not found sender in forward 'RequestConnect' message data");
      return;
    }
    final deviceService = Get.find<DeviceService>();
    final device = deviceService.getById(targetId);
    if (device == Device.unknown) {
      Log.warn(tag, "not found sender in forward 'RequestConnect' message data");
      return;
    }
    final devInfo = DevInfo.fromDevice(device);
    final devEndPoint = DeviceEndPoint(devInfo, self.host, self.port);
    _deviceConnectionQueue.add(_ConnectionEvent(endPoint: devEndPoint));
  }

  ///中转文件发送
  Future<void> _onForwardMessageSendFile(
    ForwardSocketClient self,
    Map<String, dynamic> data,
  ) async {
    final targetId = data["sender"];
    final size = data["size"].toString().toInt();
    final fileName = data["fileName"];
    final fileId = data["fileId"].toString().toInt();
    final userId = data["userId"].toString().toInt();
    //连接中转接收文件
    try {
      await FileSyncHandler.receiveFile(
        isForward: true,
        host: self.host,
        port: self.port,
        size: size,
        fileName: fileName,
        devId: targetId,
        userId: userId,
        fileId: fileId,
        context: Get.context!,
        targetId: targetId,
      );
    } catch (err, stack) {
      Log.debug(
        tag,
        "receive file failed from forward"
        "$err $stack",
      );
    }
  }

  ///中转文件接收者连接消息
  Future<void> _onForwardMessageFileReceiverConnected(
    ForwardSocketClient self,
    Map<String, dynamic> data,
  ) async {
    //接收方已连接，开始发送
    final fileId = data["fileId"].toString().toInt();
    final fileHandler = _forwardFiles[fileId];
    if (fileHandler != null) {
      fileHandler.onForwardReceiverConnected();
    } else {
      Log.warn(tag, "fileReceiverConnected but not fileId in waiting list");
    }
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

  ///endregion

  ///中转连接关闭
  Future<void> _onForwardClientDone(ForwardSocketClient self) async {
    _notifyForwardDisconnectedStatus();
    if (!self.isClosedByUser) {
      // 非主动关闭，重连中转
      connectForwardServer(true, true);
    }
  }

  ///中转连接错误
  Future<void> _onForwardClientError(
    ForwardSocketClient self,
    Object error,
    StackTrace trace,
  ) async {
    Log.error(tag, "forward client error: $e", trace);
  }

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

  ///收到设备断开消息
  Future<void> _onDeviceForget(DevInfo devInfo) async {
    final deviceService = Get.find<DeviceService>();
    final device = deviceService.getById(devInfo.guid);
    device.isPaired = false;
    await deviceService.addOrUpdate(device);
    notifyDeviceForget(devInfo);
  }

  ///收到同步消息
  Future<void> _onSyncMessage(
    SecureSocketClient client,
    MessageData msg,
  ) async {
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
            Text(
              TranslationKey.pairingCodeDialogContent.trParams({
                "devName": sender.name,
              }),
            ),
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
    MissingDataSyncHandler.sendMissingData(
      sender,
      appConfig.device.guid,
      syncedAppIds,
    );
  }

  ///收到缺失数据
  Future<void> _onMissingDataMessage(
    SecureSocketClient client,
    MessageData msg,
  ) async {
    var copyMsg = MessageData.fromJson(msg.toJson());
    var data = msg.data["data"] as Map<dynamic, dynamic>;
    copyMsg.data = data.cast<String, dynamic>();
    final total = msg.data["total"];
    int seq = msg.data["seq"];
    final syncProgressService = Get.find<HistorySyncProgressService>();
    syncProgressService.addProgress(
      copyMsg.send.guid,
      copyMsg.data,
      seq,
      total,
      false,
    );
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
    final appInfo = sourceService.appInfos.firstWhereOrNull(
      (item) => item.devId == appConfig.device.guid && appId == item.appId,
    );
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
        host: ip,
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

  ///region 在线状态测试

  ///测试设备在线状态
  Future<bool> testDeviceOnline(String devId) async {
    final socket = _devSockets[devId];
    if (socket == null) {
      return false;
    }
    return socket.testOnline();
  }

  ///设备发现心跳测试
  void startHeartbeatTest() {
    stopHeartbeatTest();
    _heartbeatTimer = Timer.periodic(appConfig.heartbeatInterval.s, (_) async {
      var sockets = _devSockets.values.toList();
      for (var skt in sockets) {
        bool online = false;
        try {
          online = await skt.testOnline();
        } catch (_) {}
        if (!online) {
          Log.warn(tag, "dev ${skt.devInfo.name} offline");
          await skt.close();
        }
      }
      if (_forwardClient != null) {
        //测试中转连接
        bool online = false;
        try {
          online = await _forwardClient?.testOnline() ?? false;
        } catch (_) {}
        if (!online) {
          Log.warn(tag, "forward client offline");
          await _forwardClient?.close();
          if(!appConfig.enableForward){
            _forwardClient = null;
          }
        }
      }
    });
  }

  ///停止心跳测试
  void stopHeartbeatTest() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  ///endregion

  ///请求缺失数据
  Future<void> reqMissingData(devId) async {
    final sourceService = Get.find<ClipboardSourceService>();
    final devSkt = _devSockets[devId];
    if (devSkt == null) {
      return;
    }
    final allAppInfos = sourceService.appInfos;
    final ownedAppIds = allAppInfos.where((item) => item.devId == devId).map((item) => item.appId).toList();
    await devSkt.sendData(MsgType.reqMissingData, {
      "appIds": ownedAppIds,
    });
  }

  ///屏幕打开
  @override
  void onScreenOpened() {
    _screenOpened = true;
    _autoCloseConnTimer?.cancel();
    Log.debug(tag, "屏幕打开");
    if (_forwardClient == null) {
      connectForwardServer(true, true);
    }
    startHeartbeatTest();
    startDiscoveryDevices(scan: appConfig.enableAutoScanOnScreenOpened);
    WakelockPlus.toggle(enable: false);
  }

  ///屏幕关闭
  @override
  void onScreenClosed() {
    _screenOpened = false;
    Log.debug(tag, "屏幕关闭");
    if (!appConfig.autoCloseConnAfterScreenOff) {
      return;
    }
    const minutes = 2;
    Log.debug(tag, "屏幕关闭，开启定时器，$minutes分钟后关闭连接");
    WakelockPlus.toggle(enable: true);
    //开启定时器，到时间自动断开连接
    _autoCloseConnTimer = Timer(minutes.min, () {
      WakelockPlus.toggle(enable: false);
      Log.debug(tag, "屏幕关闭时间已到，断开所有连接和心跳测试");
      _autoCloseConnTimer = null;
      disConnectAllConnections();
      stopHeartbeatTest();
    });
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
  void _sendMulticastMsg(MsgType key, Map<String, dynamic> data) {
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
      }
    } catch (e, stacktrace) {
      Log.debug(tag, "$e $stacktrace");
    }
  }
}
