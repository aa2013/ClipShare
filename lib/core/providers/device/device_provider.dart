import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/database/dao/device_dao.dart';
import 'package:clipshare/core/database/tables/device.dart';
import 'package:clipshare/core/providers/device/local_device_info.dart';
import 'package:clipshare/core/providers/local_device/local_device_info_provider.dart';
import 'package:clipshare/shared/enums/transport_protocol.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'device_pairing_confirm_result.dart';

part 'device_provider.g.dart';

/// 设备状态模型
@immutable
class DeviceState {
  /// guid -> 设备
  final Map<String, Device> _devices;

  /// 本机设备展示对象（未命中缓存且为本机设备时返回）
  final Device _self;

  /// 本机设备 id（用于判断请求的 id 是否本机设备）
  final String _selfId;

  const DeviceState({
    required Map<String, Device> devices,
    required Device self,
    required String selfId,
  })  : _devices = devices,
        _self = self,
        _selfId = selfId;

  /// 获取指定设备；未命中缓存时本机设备返回自身，否则返回未知设备占位
  Device getById(String id) {
    if (_devices.containsKey(id)) {
      return _devices[id]!;
    }
    return id == _selfId ? _self : unknownDevice();
  }

  /// 获取指定设备的展示名
  String getName(String id) => getById(id).displayName;

  /// 设备 id -> 展示名 映射
  Map<String, String> toIdNameMap() => {for (final e in _devices.entries) e.key: e.value.displayName};

  /// 已配对设备列表
  List<Device> get pairedList => _devices.values.where((dev) => dev.isPaired).toList();

  List<Device> get list => _devices.values.toList(growable: false);

  /// 本机设备（筛选设备时需包含本机）
  Device get self => _self;
}

@Riverpod(keepAlive: true)
class DeviceNotifier extends _$DeviceNotifier {
  static const tag = 'DeviceProvider';

  /// 运行态配对来源优先级，仅用于配对状态仲裁，不暴露给调用方
  final _pairingSources = <String, _PairingSourceState>{};

  DeviceDao get _deviceDao => ref.read(appDbProvider).requireValue.deviceDao;

  BaseDeviceInfo get _baseDevInfo => ref.read(localDeviceInfoProvider).requireValue.baseDeviceInfo;

  Device get _self => ref.read(localDeviceInfoProvider).requireValue.self;

  /// 当前设备状态基准（state 尚未就绪时返回空数据）
  DeviceState get _current =>
      state.value ??
      DeviceState(
        devices: const <String, Device>{},
        self: _self,
        selfId: _baseDevInfo.id,
      );

  @override
  Future<DeviceState> build() async {
    final lst = await _deviceDao.getAllDevices(0);
    final devices = <String, Device>{};
    for (var dev in lst) {
      devices[dev.guid] = dev;
    }
    return DeviceState(devices: devices, self: _self, selfId: _baseDevInfo.id);
  }

  Future<bool> _addOrUpdate(Device device) async {
    var v = await _deviceDao.getById(device.guid, 0);
    if (v == null) {
      return await _deviceDao.add(device) > 0;
    } else {
      return await _deviceDao.updateDevice(device) > 0;
    }
  }

  Future<bool> addOrUpdate(Device device) async {
    var res = await _addOrUpdate(device);
    if (res) {
      final current = _current;
      // 直接更新共享 map，靠新 DeviceState 实例（identity 变化）触发 watch 刷新
      current._devices[device.guid] = device;
      state = AsyncData(DeviceState(
        devices: current._devices,
        self: _self,
        selfId: _baseDevInfo.id,
      ));
    }
    return res;
  }

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
        isPaired: _current._devices[devId]?.isPaired ?? previous.isPaired,
        changed: false,
      );
    }

    final existing = await _deviceDao.getById(devId, 0);
    final merged = (existing ?? device).copyWith(
      devName: device.devName.isEmpty ? existing?.devName : device.devName,
      type: device.type.isEmpty ? existing?.type : device.type,
      address: Value(device.address ?? existing?.address ?? protocol.name),
      internalAddress: Value(device.internalAddress ?? existing?.internalAddress),
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
  void clearPairingSource(String devId, TransportProtocol protocol, {bool force = false}) {
    final previous = _pairingSources[devId];
    if (previous == null) {
      return;
    }
    if (!force && (previous.manual || previous.priority != _pairingPriority(protocol))) {
      return;
    }
    _pairingSources.remove(devId);
  }

  Future<bool> remove(String devId) async {
    final cnt = await _deviceDao.remove(devId, 0) ?? 0;
    final success = cnt > 0;
    if (success) {
      _pairingSources.remove(devId);
      final current = _current;
      // 直接更新共享 map，靠新 DeviceState 实例（identity 变化）触发 watch 刷新
      current._devices.remove(devId);
      state = AsyncData(DeviceState(
        devices: current._devices,
        self: _self,
        selfId: _baseDevInfo.id,
      ));
    }
    return success;
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
