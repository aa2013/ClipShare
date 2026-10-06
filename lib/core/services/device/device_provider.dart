import 'dart:async';
import 'dart:math';

import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/database/dao/device_dao.dart';
import 'package:clipshare/core/database/tables/device.dart';
import 'package:clipshare/core/services/device/events/device_discovery_event.dart';
import 'package:clipshare/core/services/device/local_device_info.dart';
import 'package:clipshare/core/services/device/local_device_info_provider.dart';
import 'package:clipshare/shared/enums/transport_protocol.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'device_pairing_confirm_result.dart';
import 'device_registry.dart';
import 'events/device_lifecycle_event.dart';

part 'device_provider.g.dart';

/// 设备状态模型
@immutable
class DeviceState {
  /// 已存储的设备信息，guid -> 设备
  final Map<String, Device> _storedDevices;

  /// 发现的设备信息（未存储） guid -> 设备
  final Map<String, BaseDeviceInfo> _discoveryDevices;

  /// 设备注册中心
  final DeviceRegistry registry;

  /// 本机设备展示对象（未命中缓存且为本机设备时返回）
  final Device self;

  /// 本机设备 id（用于判断请求的 id 是否本机设备）
  final String _selfId;

  ///发现的设备列表
  List<BaseDeviceInfo> get discoveryList => _discoveryDevices.values.toList(growable: false);

  /// 已配对设备列表
  List<Device> get pairedList => _storedDevices.values.where((dev) => dev.isPaired).toList();

  ///在线且已配对列表
  List<BaseDeviceInfo> get onlineList {
    final list = [...discoveryList];
    list.addAll(pairedList.map(BaseDeviceInfo.fromDevice));
    return list.where((dev) => registry.getProtocol(dev.guid) != null).toList();
  }

  ///在线且已配对列表
  List<Device> get onlineAndPairedList => pairedList.where((dev) => registry.getProtocol(dev.guid) != null).toList();

  ///离线且已配对列表
  List<Device> get offlineAndPairedList => pairedList.where((dev) => registry.getProtocol(dev.guid) == null).toList();

  ///本机已存储的设备列表（含取消配对的）
  List<Device> get storedList => _storedDevices.values.toList(growable: false);

  const DeviceState({
    required Map<String, Device> storedDevices,
    required Map<String, BaseDeviceInfo> discoveryDevices,
    required this.registry,
    required this.self,
    required String selfId,
  }) : _storedDevices = storedDevices,
       _discoveryDevices = discoveryDevices,
       _selfId = selfId;

  DeviceState copyWith({
    Map<String, Device>? storedDevices,
    Map<String, BaseDeviceInfo>? discoveryDevices,
    DeviceRegistry? registry,
    Device? self,
    String? selfId,
  }) {
    return DeviceState(
      storedDevices: storedDevices ?? _storedDevices,
      discoveryDevices: discoveryDevices ?? _discoveryDevices,
      registry: registry ?? this.registry,
      self: self ?? this.self,
      selfId: selfId ?? _selfId,
    );
  }

  /// 获取指定设备；未命中缓存时本机设备返回自身，否则返回未知设备占位
  Device? getStoredById(String id) {
    if (_storedDevices.containsKey(id)) {
      return _storedDevices[id]!;
    }
    return id == _selfId ? self : null;
  }

  /// 获取指定设备的展示名
  String? getStoredName(String id) => getStoredById(id)?.displayName;

  /// 设备 id -> 展示名 映射
  Map<String, String> toStoredIdNameMap() => {
    for (final e in _storedDevices.entries) e.key: e.value.displayName,
  };
}

@Riverpod(keepAlive: true)
class DeviceNotifier extends _$DeviceNotifier {
  static const tag = 'DeviceProvider';

  /// 运行态配对来源优先级，仅用于配对状态仲裁，不暴露给调用方
  final _pairingSources = <String, _PairingSourceState>{};

  /// 已存储的设备列表
  final _storedDevices = <String, Device>{};

  /// 已发现的设备列表
  final _discoveryDevices = <String, BaseDeviceInfo>{};

  ///设备协议注册表
  final _registry = DeviceRegistry();

  DeviceDao get _deviceDao => ref.read(appDbProvider).requireValue.deviceDao;

  BaseDeviceInfo get _baseDevInfo => ref.read(localDeviceInfoProvider).requireValue.baseDeviceInfo;

  Device get _self => ref.read(localDeviceInfoProvider).requireValue.self;

  ///设备连接生命周期事件
  final _lifecycleEvents = StreamController<DeviceLifecycleEvent>.broadcast();

  Stream<DeviceLifecycleEvent> get lifecycleEvents => _lifecycleEvents.stream;

  ///设备发现生命周期事件
  final _discoveryEvents = StreamController<DeviceDiscoveryEvent>.broadcast();

  Stream<DeviceDiscoveryEvent> get discoveryEvents => _discoveryEvents.stream;

  @override
  Future<DeviceState> build() async {
    final lst = await _deviceDao.getAllDevices();
    final devices = <String, Device>{};
    for (var dev in lst) {
      devices[dev.guid] = dev;
    }
    return DeviceState(
      storedDevices: devices,
      discoveryDevices: _discoveryDevices,
      registry: DeviceRegistry(),
      self: _self,
      selfId: _baseDevInfo.guid,
    );
  }

  Future<bool> addOrUpdate(Device device) async {
    var value = await _deviceDao.getById(device.guid);
    var success = false;
    if (value == null) {
      success = await _deviceDao.add(device) > 0;
    } else {
      success = await _deviceDao.updateDevice(device) > 0;
    }
    if (success) {
      _storedDevices[device.guid] = device;
      //移除发现记录
      _discoveryDevices.remove(device.guid);
      _updateState();
    }
    return success;
  }

  Future<bool> remove(String devId) async {
    final cnt = await _deviceDao.remove(devId) ?? 0;
    final success = cnt > 0;
    if (success) {
      _pairingSources.remove(devId);
      _storedDevices.remove(devId);
      _updateState();
    }
    return success;
  }

  void _updateState() {
    state = AsyncData(
      DeviceState(
        storedDevices: _storedDevices,
        discoveryDevices: _discoveryDevices,
        registry: _registry,
        self: _self,
        selfId: _baseDevInfo.guid,
      ),
    );
  }

  //region events
  void emitLifecycleEvent(DeviceLifecycleEvent event) {
    if (event is DeviceConnected) {
      final id = event.device.guid;
      //未存储该设备
      if (!_storedDevices.containsKey(id)) {
        _discoveryDevices[id] = event.device;
      }
    } else if (event is DeviceDisconnected) {
      final id = event.deviceId;
      _discoveryDevices.remove(id);
    }
    _lifecycleEvents.add(event);
  }

  void emitDiscoveryEvent(DeviceDiscoveryEvent event) {
    _discoveryEvents.add(event);
  }

  //endregion

  /// 统一确认设备配对状态，避免不同传输服务各自直接写 isPaired 造成状态打架。
  Future<DevicePairingConfirmResult> confirmPairingState({
    required Device device,
    required bool localIsPaired,
    required bool remoteIsPaired,
    required TransportProtocol protocol,
    bool manual = false,
  }) async {
    final nextPaired = localIsPaired && remoteIsPaired;
    final devId = device.guid;
    final previous = _pairingSources[devId];
    final nextPriority = _pairingPriority(protocol);

    // 手动状态用于挡住 storage 自恢复，但有效 socket 仍可用实时配对状态覆盖。
    final previousBlocks = previous != null && (previous.priority > nextPriority || (previous.manual && !protocol.isSocket));
    if (!manual && previousBlocks) {
      logger.info(tag, '!manual && previousBlocks');
      return DevicePairingConfirmResult(
        accepted: false,
        isPaired: _storedDevices[devId]?.isPaired ?? previous.isPaired,
        changed: false,
      );
    }

    final existing = await _deviceDao.getById(devId);
    final merged = (existing ?? device).copyWith(
      devName: device.devName.isEmpty ? existing?.devName : device.devName,
      type: device.type.isEmpty ? existing?.type : device.type,
      address: Value(device.address ?? existing?.address ?? protocol.name),
      internalAddress: Value(
        device.internalAddress ?? existing?.internalAddress,
      ),
      isPaired: nextPaired,
    );
    final changed = existing?.isPaired != nextPaired;
    final success = await addOrUpdate(merged);
    if (!success) {
      logger.info(tag, 'confirmPairingState addOrUpdate false');
      return DevicePairingConfirmResult(
        accepted: false,
        isPaired: existing?.isPaired ?? false,
        changed: false,
      );
    }
    _pairingSources[devId] = _PairingSourceState(
      priority: nextPriority,
      isPaired: nextPaired,
      manual: manual,
    );
    return DevicePairingConfirmResult(
      accepted: true,
      isPaired: nextPaired,
      changed: changed,
      device: merged,
    );
  }

  /// 设备连接断开后，移除该协议来源的运行态优先级，允许 storage 在无 socket 时恢复可信配对。
  /// [force] 为 true 时强制清除（含 manual 配对来源），用于 socket 会话关闭后允许存储接管。
  void clearPairingSource(
    String devId,
    TransportProtocol protocol, {
    bool force = false,
  }) {
    final previous = _pairingSources[devId];
    if (previous == null) {
      return;
    }
    if (!force && (previous.manual || previous.priority != _pairingPriority(protocol))) {
      return;
    }
    _pairingSources.remove(devId);
  }
}

class _PairingSourceState {
  final int priority;
  final bool isPaired;
  final bool manual;

  const _PairingSourceState({
    required this.priority,
    required this.isPaired,
    this.manual = false,
  });
}

int _pairingPriority(TransportProtocol protocol) {
  if (protocol.isSocket) return 2;
  return 1;
}
