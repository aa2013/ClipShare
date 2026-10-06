import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:clipshare/core/constants/network_constants.dart' as net;
import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/database/dao/device_dao.dart';
import 'package:clipshare/core/runtime/app_state/app_state_provider.dart';
import 'package:clipshare/core/services/device/device_provider.dart';
import 'package:clipshare/core/services/device/events/device_discovery_event.dart';
import 'package:clipshare/core/services/device/local_device_info.dart';
import 'package:clipshare/core/services/device/local_device_info_provider.dart';
import 'package:clipshare/core/services/transport/socket/direct/direct_provider.dart';
import 'package:clipshare/core/services/transport/socket/forward/forward_server_provider.dart';
import 'package:clipshare/core/settings/discovery/discovery_settings.dart';
import 'package:clipshare/core/settings/discovery/discovery_settings_provider.dart';
import 'package:clipshare/core/settings/forward/forward_settings.dart';
import 'package:clipshare/core/settings/forward/forward_settings_provider.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/extensions/number_extension.dart';
import 'package:clipshare/shared/utils/crypto.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:clipshare/shared/utils/network_util.dart';
import 'package:clipshare/shared/utils/parallerl_task.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../enums/msg_type.dart';
import '../../models/message_data.dart';

part 'discovery_provider.g.dart';

/// 设备发现状态。
/// 负责组播、子网、已配对设备和中转设备发现，不拥有连接会话。
@Riverpod(keepAlive: true)
class DiscoveryNotifier extends _$DiscoveryNotifier {
  static const _tag = 'DiscoveryNotifier';
  static const _maxParallelCount = 10;
  CancelTokenSource _tokenSource = CancelTokenSource();
  final Map<String, Future<void>> _broadcastTasks = {};
  List<RawDatagramSocket> _multicastSockets = [];

  DeviceNotifier get _deviceNotifier => ref.read(deviceProvider.notifier);

  ForwardServerNotifier get _forwardServerNotifier => ref.read(forwardServerProvider.notifier);

  DirectNotifier get _directNotifier => ref.read(directProvider.notifier);

  LocalDeviceInfo get _localDeviceInfo => ref.read(localDeviceInfoProvider).requireValue;

  BaseDeviceInfo get _self => _localDeviceInfo.baseDeviceInfo;

  DiscoverySettings get _discoverySettings => ref.read(discoverySettingsProvider).requireValue;

  ForwardSettings get _forwardSettings => ref.read(forwardSettingsProvider).requireValue;

  DeviceDao get _deviceDao => ref.read(appDbProvider).requireValue.deviceDao;

  @override
  bool build() {
    ref.onDispose(_dispose);
    return false;
  }

  void _dispose() {
    _tokenSource.cancel();
    _closeMulticastSockets();
  }

  /// 启动设备发现流程。
  Future<void> startDiscoveryDevices({bool restart = false, bool scan = true, bool manual = false}) async {
    if (state) return;
    final appState = ref.read(appStateProvider);
    if (appState.currentNetworkType == .none) {
      return;
    }
    final appStateNotifier = ref.read(appStateProvider.notifier);
    state = true;
    _deviceNotifier.emitDiscoveryEvent(const DeviceDiscoveryStarted());
    _tokenSource.cancel();
    _tokenSource = CancelTokenSource();
    final token = _tokenSource.token;
    try {
      if (!_discoverySettings.onlyForwardMode) {
        await _startListenMulticast();
      }
      //连接已配对设备
      appStateNotifier.updateDeviceDiscoveryStatus(TranslationKey.deviceDiscoveryStatusViaPaired.tr);
      final paired = _discoverySettings.onlyForwardMode ? <Future<void> Function()>[] : await _pairedDiscovering(token);
      await ParallelTask(tasks: paired, maxParallelCnt: _maxParallelCount, token: token).run();
      if (token.isCanceled) return;
      //广播发现
      appStateNotifier.updateDeviceDiscoveryStatus(TranslationKey.deviceDiscoveryStatusViaBroadcast.tr);
      final mobile = appState.currentNetworkType == .mobile && !kIsWeb;
      final broadcasts = mobile || !scan ? <Future<void> Function()>[] : _multicastDiscovering(token);
      await ParallelTask(tasks: broadcasts, maxParallelCnt: 1, token: token).run();
      if (token.isCanceled) return;
      //子网扫描
      appStateNotifier.updateDeviceDiscoveryStatus(TranslationKey.deviceDiscoveryStatusViaScan.tr);
      final subnet = mobile || !scan || _discoverySettings.onlyForwardMode ? <Future<void> Function()>[] : await _subNetDiscovering(token, manual);
      await ParallelTask(tasks: subnet, maxParallelCnt: _maxParallelCount, token: token).run();
      if (token.isCanceled) return;
      //中转服务发现
      appStateNotifier.updateDeviceDiscoveryStatus(TranslationKey.deviceDiscoveryStatusViaForward.tr);
      final forwards = scan ? await _forwardDiscovering(token) : <Future<void> Function()>[];
      await ParallelTask(tasks: forwards, maxParallelCnt: _maxParallelCount, token: token).run();
    } finally {
      if (identical(_tokenSource.token, token)) {
        state = false;
        //todo 这里应该不关闭组播监听
        _closeMulticastSockets();
      }
      //设备发现流程结束
      appStateNotifier.updateDeviceDiscoveryStatus(null);
      _deviceNotifier.emitDiscoveryEvent(const DeviceDiscoveryFinished());
    }
  }

  /// 停止发现并释放组播 socket 及全部未完成任务。
  Future<void> stopDiscoveryDevices([bool restart = false]) async {
    _tokenSource.cancel();
    _broadcastTasks.clear();
    _closeMulticastSockets();
    state = false;
    if (!restart) {
      final appStateNotifier = ref.read(appStateProvider.notifier);
      appStateNotifier.updateDeviceDiscoveryStatus(null);
      _deviceNotifier.emitDiscoveryEvent(const DeviceDiscoveryFinished());
    }
  }

  /// 重新启动发现。
  Future<void> restartDiscoveryDevices() async {
    await stopDiscoveryDevices(true);
    await startDiscoveryDevices(restart: true);
  }

  //监听组播消息
  Future<void> _startListenMulticast() async {
    _closeMulticastSockets();
    _multicastSockets = await _getMulticastSockets(net.multicastGroup, _discoverySettings.port);
    for (final socket in _multicastSockets) {
      socket.listen((_) {
        final datagram = socket.receive();
        if (datagram == null) return;
        try {
          final json = jsonDecode(CryptoUtil.base64DecodeStr(utf8.decode(datagram.data))) as Map<String, dynamic>;
          final msg = MessageData.fromJson(json);
          if (msg.send.guid == _self.guid) return;
          if (msg.key == MsgType.broadcastInfo) _runSingleBroadcastCandidate(msg, datagram);
        } catch (error, stackTrace) {
          logger.debug(_tag, 'Invalid multicast discovery message: $error $stackTrace');
        }
      });
    }
  }

  void _runSingleBroadcastCandidate(MessageData msg, Datagram datagram) {
    final id = msg.send.guid;
    if (_broadcastTasks.containsKey(id)) {
      return;
    }
    late final Future<void> task;
    task = _onBroadcastInfoReceived(msg, datagram).whenComplete(() => _broadcastTasks.remove(id));
    _broadcastTasks[id] = task;
  }

  Future<void> _onBroadcastInfoReceived(MessageData msg, Datagram datagram) async {
    final device = await _deviceDao.getById(msg.send.guid);
    if (!_discoverySettings.allowDiscovery && !(device?.isPaired ?? false)) {
      return;
    }
    final port = (msg.data['port'] as num?)?.toInt();
    if (port == null) {
      return;
    }
    await _directNotifier.connect(
      datagram.address.address,
      port: port,
      targetDevId: msg.send.guid,
      cancelToken: _tokenSource.token,
    );
  }

  List<Future<void> Function()> _multicastDiscovering(CancelToken token) {
    final tasks = <Future<void> Function()>[];
    for (final delay in const [100, 500, 2000, 5000]) {
      tasks.add(() async {
        if (token.isCanceled) {
          return;
        }
        await Future<void>.delayed(delay.ms);
        if (!token.isCanceled) {
          _directNotifier.sendMulticastMsg(
            MsgType.broadcastInfo,
            {
              'port': _directNotifier.serverPort,
            },
          );
        }
      });
    }
    return tasks;
  }

  Future<List<Future<void> Function()>> _subNetDiscovering(CancelToken token, bool manual) async {
    if (!manual && _discoverySettings.onlyManualDiscoverySubNet) {
      return [];
    }
    final tasks = <Future<void> Function()>[];
    final interfaces = (await NetworkUtil.listInterfaces()).where((item) => !_discoverySettings.noDiscoveryIfs.contains(item.name));
    for (final address in interfaces.expand((item) => item.addresses).where((item) => item.type == InternetAddressType.IPv4)) {
      final prefix = address.address.split('.').take(3).join('.');
      for (var i = 0; i < 255; i++) {
        final host = '$prefix.$i';
        tasks.add(
          () => _directNotifier.connect(
            host,
            sourceAddress: address.address,
            cancelToken: token,
          ),
        );
      }
    }
    return tasks;
  }

  Future<List<Future<void> Function()>> _pairedDiscovering(CancelToken token) async {
    final tasks = <Future<void> Function()>[];
    final devices = await _deviceDao.getAllDevices();
    for (final device in devices) {
      tasks.add(() async {
        if (token.isCanceled) {
          return;
        }
        var connected = false;
        final address = device.internalAddress;
        if (address != null && address.contains(':')) {
          final parts = address.split(':');
          connected = await _directNotifier.connect(
            parts[0],
            port: int.tryParse(parts[1]),
            targetDevId: device.guid,
            cancelToken: token,
          );
        }
        if (!connected && _forwardServerNotifier.connected) {
          await _forwardServerNotifier.connectDevice(
            device.guid,
            cancelToken: token,
          );
        }
      });
    }
    return tasks;
  }

  Future<List<Future<void> Function()>> _forwardDiscovering(CancelToken token) async {
    final tasks = <Future<void> Function()>[];
    if (!_forwardServerNotifier.connected || !_forwardSettings.enable) {
      return tasks;
    }
    for (final device in await _deviceDao.getAllDevices()) {
      tasks.add(() => _forwardServerNotifier.connectDevice(device.guid, cancelToken: token));
    }
    return tasks;
  }

  void _closeMulticastSockets() {
    for (final socket in _multicastSockets) {
      socket.close();
    }
    _multicastSockets = [];
  }

  Future<List<RawDatagramSocket>> _getMulticastSockets(String group, [int port = 0]) async {
    final interfaces = (await NetworkUtil.listInterfaces()).where((item) => !_discoverySettings.noDiscoveryIfs.contains(item.name));
    final result = <RawDatagramSocket>[];
    for (final interface in interfaces) {
      final address = interface.addresses.where((item) => item.type == InternetAddressType.IPv4).firstOrNull;
      if (address == null) continue;
      try {
        final socket = await RawDatagramSocket.bind(address, port);
        socket.joinMulticast(InternetAddress(group), interface);
        result.add(socket);
      } catch (error, stackTrace) {
        logger.debug(_tag, 'Failed to bind multicast socket: $error $stackTrace');
      }
    }
    return result;
  }
}
