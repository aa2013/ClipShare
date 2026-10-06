import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:clipshare/core/constants/app_constants.dart';
import 'package:clipshare/core/constants/network_constants.dart' as net;
import 'package:clipshare/core/database/app_database.dart';
import 'package:clipshare/core/database/tables/device.dart';
import 'package:clipshare/core/services/device/device_provider.dart';
import 'package:clipshare/core/services/device/local_device_info.dart';
import 'package:clipshare/core/services/device/local_device_info_provider.dart';
import 'package:clipshare/core/services/transport/models/socket_crypto_config.dart';
import 'package:clipshare/core/settings/device/device_settings.dart';
import 'package:clipshare/core/settings/device/device_settings_provider.dart';
import 'package:clipshare/core/settings/discovery/discovery_settings.dart';
import 'package:clipshare/core/settings/discovery/discovery_settings_provider.dart';
import 'package:clipshare/shared/extensions/string_extension.dart';
import 'package:clipshare/shared/utils/crypto.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:clipshare/shared/utils/network_util.dart';
import 'package:clipshare/shared/utils/parallerl_task.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../client/socket/secure_socket_client.dart';
import '../../client/socket/secure_socket_server.dart';
import '../../enums/msg_type.dart';
import '../../models/local_socket_base_info.dart';
import '../../models/message_data.dart';
import '../session/device_connection_queue.dart';
import '../session/session_provider.dart';

part 'direct_provider.g.dart';

@Riverpod(keepAlive: true)
class DirectNotifier extends _$DirectNotifier {
  static const String tag = 'SocketService';
  static const maxParallelCnt = 10;

  /// 根据设备id加载已保存设备
  Device? _loadDevice(String guid) => ref.read(deviceProvider).requireValue.getStoredById(guid);

  Device? loadDevice(String guid) => _loadDevice(guid);

  DiscoverySettings get _discoverySettings => ref.read(discoverySettingsProvider).requireValue;

  LocalDeviceInfo get _localDeviceInfo => ref.read(localDeviceInfoProvider).requireValue;

  BaseDeviceInfo get _self => _localDeviceInfo.baseDeviceInfo;

  DeviceSettings get _deviceSettings => ref.read(deviceSettingsProvider).requireValue;

  LocalSocketBaseInfo get _localBaseInfo => LocalSocketBaseInfo(
    cryptoConfig: SocketCryptoConfig(prime1: prime1, prime2: prime2, dhAesKey: _deviceSettings.dhAesKey),
    baseDeviceInfo: _self,
    localListenPort: _discoverySettings.port,
    localVersion: _localDeviceInfo.appVersion,
    minVersion: minVersion,
    allowDiscover: _discoverySettings.allowDiscovery,
  );

  /// 提供给 ForwardNotifier 的握手参数和消息回调，不维护中转状态。
  LocalSocketBaseInfo get localBaseInfo => _localBaseInfo;

  SessionNotifier get _sessionNotifier => ref.read(sessionProvider.notifier);

  /// Socket 监听服务端，入站 client ready 后才进入业务层。
  late SecureSocketServer _server;

  /// 启动标记，避免重复启动初始化。
  bool _started = false;

  /// 本地直连服务监听端口。
  int get serverPort => _server.port;

  @override
  void build() {
    ref.onDispose(_dispose);
    unawaited(Future.microtask(_runSocketServer));
  }

  Future<void> _runSocketServer() async {
    if (_started) {
      return;
    }
    _started = true;
    _server = await SecureSocketServer.bind(
      ip: '0.0.0.0',
      port: _discoverySettings.port,
      baseInfo: _localBaseInfo,
      loadDevice: _loadDevice,
      onConnected: (ip, port) {
        logger.debug(
          tag,
          'New connection from ip:$ip port:$port',
        );
      },
      onClientReady: (client) {
        unawaited(_sessionNotifier.registerCandidate(client));
      },
      onMessage: (client, json) {
        final msg = MessageData.fromJson(json);
        unawaited(_sessionNotifier.onSocketReceived(client, msg));
      },
      onError: (err) {
        logger.error(tag, 'Socket server error: $err');
      },
      onClientError: (e, ip, port, client) {
        _sessionNotifier.handleTransportClosed(client, reason: 'server client error: $e');
      },
      onClientDone: (ip, port, client) {
        _sessionNotifier.handleTransportClosed(client, reason: 'server client done');
      },
      onDone: () {
        logger.debug(tag, 'Socket server closed');
        for (final session in _sessionNotifier.sessions.snapshot()) {
          if (!session.socket.isForwardMode) {
            unawaited(_sessionNotifier.closeSession(session.dev.guid, session.socket, reason: 'server closed'));
          }
        }
      },
    );
  }

  void _dispose() {
    unawaited(_server.close());
  }

  ///连接 ip
  ///创建一个直连候选并交给 SessionNotifier 登记。
  Future<bool> connect(
    String host, {
    String? sourceAddress,
    int? port,
    Function? onErr,
    Map<String, dynamic> data = const {},
    String? targetDevId,
    CancelToken? cancelToken,
  }) async {
    port = port ?? net.port;
    // 中转连接由 ForwardNotifier 提供；此入口只创建直连候选。
    final address = '$host:$port:$targetDevId';
    try {
      if (data['stop'] == true || (cancelToken?.isCanceled ?? false)) {
        return false;
      }
      final tokenSource = CancelTokenSource();
      final token = tokenSource.token.combine(cancelToken);
      final request = DeviceConnectionRequest(
        workerKey: targetDevId ?? address,
        expectedDevId: targetDevId,
        description: 'direct connect $host:$port',
        token: token,
        connect: (token) {
          return SecureSocketClient.connect(
            ip: host,
            sourceAddress: sourceAddress,
            port: port!,
            localBaseInfo: _localBaseInfo,
            loadDevice: _loadDevice,
            onMessage: (client, json) {
              final msg = MessageData.fromJson(json);
              unawaited(_sessionNotifier.onSocketReceived(client, msg));
            },
            onDone: (client) => _sessionNotifier.handleTransportClosed(client, reason: 'manual direct done'),
            onError: (error, client) => _sessionNotifier.handleTransportClosed(client, reason: 'manual direct error: $error'),
            cancelToken: token,
          );
        },
      );
      final result = await _sessionNotifier.submitCandidate(request);
      if (result) {
        _sessionNotifier.rememberPairingAddress('$host:$port');
      }
      return result;
    } catch (error, stackTrace) {
      logger.debug(tag, 'Manual Socket connect failed. host=$host, port=$port, error=$error $stackTrace');
      onErr?.call(error);
      return false;
    }
  }

  /// 发送组播消息
  void sendMulticastMsg(
    MsgType key,
    Map<String, dynamic> data, [
    BaseDeviceInfo? receiver,
  ]) async {
    MessageData msg = MessageData(
      send: _self,
      key: key,
      data: data,
      recv: receiver,
    );
    try {
      var b64Data = CryptoUtil.base64EncodeStr('${msg.toJsonStr()}\n');
      var multicasts = await _getSockets(net.multicastGroup);
      for (var multicast in multicasts) {
        multicast.send(
          utf8.encode(b64Data),
          InternetAddress(net.multicastGroup),
          _discoverySettings.port,
        );
        multicast.close();
      }
    } catch (e, stacktrace) {
      logger.debug(tag, '$e $stacktrace');
    }
  }

  Future<List<RawDatagramSocket>> _getSockets(
    String multicastGroup, [
    int port = 0,
  ]) async {
    const ipv4Type = InternetAddressType.IPv4;
    final interfaces = (await NetworkUtil.listInterfaces()).where((itf) => !_discoverySettings.noDiscoveryIfs.contains(itf.name)).where((itf) => itf.addresses.any((addr) => addr.type == ipv4Type));

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
}
