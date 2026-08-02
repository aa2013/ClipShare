import 'package:clipshare/app/data/repository/entity/tables/device.dart';
import 'package:clipshare/app/data/enums/transport_protocol.dart';
import 'package:clipshare/app/listeners/device_remove_listener.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:drift/drift.dart' show Value;
import 'package:get/get.dart' hide Value;

class DeviceService extends GetxService {
  static const tag = "DeviceService";
  final _dbService = Get.find<DbService>();
  final _appConfig = Get.find<ConfigService>();
  final _devices = <String, Device>{}.obs;
  final _listeners = <DeviceRemoveListener>[];
  final _pairingSources = <String, _PairingSourceState>{};

  Future<DeviceService> init() async {
    final lst = await _dbService.deviceDao.getAllDevices(_appConfig.userId);
    for (var dev in lst) {
      _devices[dev.guid] = dev;
    }
    return this;
  }

  void addDevRemoveListener(DeviceRemoveListener listener){
    _listeners.add(listener);
  }

  void removeDevRemoveListener(DeviceRemoveListener listener){
    _listeners.remove(listener);
  }

  Device getById(String id) {
    if (_devices.containsKey(id)) {
      return _devices[id]!;
    }
    return id == _appConfig.device.guid ? _appConfig.device : unknownDevice();
  }

  String getName(String id) {
    return getById(id).displayName;
  }

  Map<String, String> toIdNameMap() {
    Map<String, String> res = {};
    _devices.forEach((key, value) {
      res[key] = value.displayName;
    });
    return res;
  }

  List<Device> get pairedList {
    return _devices.values.where((dev) => dev.isPaired).toList();
  }

  Future<bool> _addOrUpdate(Device device) async {
    var v = await _dbService.deviceDao.getById(device.guid, _appConfig.userId);
    if (v == null) {
      return await _dbService.deviceDao.add(device) > 0;
    } else {
      return await _dbService.deviceDao.updateDevice(device) > 0;
    }
  }

  Future<bool> addOrUpdate(Device device) async {
    var res = await _addOrUpdate(device);
    if (res) {
      _devices[device.guid] = device;
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
    final previousBlocks = previous != null &&
        (previous.priority > nextPriority || (previous.manual && !protocol.isSocket));
    if (!manual && previousBlocks) {
      logger.info(tag, "!manual && previousBlocks");
      return DevicePairingConfirmResult(
        accepted: false,
        isPaired: _devices[devId]?.isPaired ?? previous.isPaired,
        changed: false,
      );
    }

    final existing = await _dbService.deviceDao.getById(devId, _appConfig.userId);
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
      logger.info(tag, "confirmPairingState addOrUpdate false");
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
  void clearPairingSource(String devId, TransportProtocol protocol) {
    final previous = _pairingSources[devId];
    if (previous == null || previous.manual || previous.priority != _pairingPriority(protocol)) {
      return;
    }
    _pairingSources.remove(devId);
  }

  Future<bool> remove(String devId) async {
    final cnt = await _dbService.deviceDao.remove(devId, _appConfig.userId) ?? 0;
    final success = cnt > 0;
    if(success){
      _pairingSources.remove(devId);
      for(var listener in _listeners){
        listener.onRemove(devId);
      }
    }
    return success;
  }
}

class DevicePairingConfirmResult {
  final bool accepted;
  final bool isPaired;
  final bool changed;
  final Device? device;

  const DevicePairingConfirmResult({
    required this.accepted,
    required this.isPaired,
    required this.changed,
    this.device,
  });
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
