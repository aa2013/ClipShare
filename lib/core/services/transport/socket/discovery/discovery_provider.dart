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

  DeviceState get _deviceState => ref.read(deviceProvider).requireValue;

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
    // 组播监听与应用同生命周期常驻；发现设置变化时重建监听。
    unawaited(Future.microtask(_ensureMulticastListener));
    ref.listen(discoverySettingsProvider, (_, next) {
      next.whenData((_) => unawaited(_ensureMulticastListener()));
    });
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
      await _ensureMulticastListener();
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
      }
      //设备发现流程结束
      appStateNotifier.updateDeviceDiscoveryStatus(null);
      _deviceNotifier.emitDiscoveryEvent(const DeviceDiscoveryFinished());
    }
  }

  /// 停止发现并取消全部未完成任务
  Future<void> stopDiscoveryDevices([bool restart = false]) async {
    _tokenSource.cancel();
    _broadcastTasks.clear();
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

  /// 正在进行的监听重建任务，避免并发触发导致 socket 重复绑定或泄漏。
  Future<void>? _ensureMulticastTask;

  /// 确保组播监听与最新设置一致：全部关闭现役监听后按当前设置重建；
  /// 仅中转模式下只关不建。
  /// [startDiscoveryDevices] 每轮开始、应用启动和设置变化时都会触发，
  /// 重建耗时很短且对被动监听低频场景无实际影响。
  Future<void> _ensureMulticastListener() {
    return _ensureMulticastTask ??= _rebuildMulticastListener().whenComplete(() => _ensureMulticastTask = null);
  }

  /// 全关全建组播监听
  Future<void> _rebuildMulticastListener() async {
    _closeMulticastSockets();
    if (_discoverySettings.onlyForwardMode) {
      return;
    }
    _multicastSockets = await NetworkUtil.bindMulticastSockets(
      net.multicastGroup,
      _discoverySettings.port,
      noDiscoveryIfs: _discoverySettings.noDiscoveryIfs,
    );
    for (final socket in _multicastSockets) {
      socket.listen((_) {
        final datagram = socket.receive();
        if (datagram == null) {
          return;
        }
        logger.debug(_tag, 'receive socket from multicast: ${datagram.address.address}:${datagram.port}');
        try {
          final json = jsonDecode(CryptoUtil.base64DecodeStr(utf8.decode(datagram.data))) as Map<String, dynamic>;
          final msg = MessageData.fromJson(json);
          if (msg.send.guid == _self.guid) {
            return;
          }
          if (msg.key == .broadcastInfo) {
            _runSingleBroadcastCandidate(msg, datagram);
          }
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
    // 被动广播连接不使用发现轮次的取消令牌：
    // 用户手动停止发现后轮次令牌已失效，被动发现仍应可自动连接。
    await _directNotifier.connect(
      datagram.address.address,
      port: port,
      targetDevId: msg.send.guid,
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
    final pairedList = _deviceState.pairedList;
    for (final device in pairedList) {
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
}
