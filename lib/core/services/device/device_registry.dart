import 'package:clipshare/shared/enums/transport_protocol.dart';

import 'local_device_info.dart';

/// 设备注册中心
class DeviceRegistry {
  /// 已连接设备的协议，设备基础信息 -> 协议
  final Map<BaseDeviceInfo, TransportProtocol> _devProtocols;

  const DeviceRegistry({
    required Map<BaseDeviceInfo, TransportProtocol> devProtocols,
  }) : _devProtocols = devProtocols;

  bool hasDevice(String devId) {
    return _devProtocols.keys.where((item) => item.guid == devId).isNotEmpty;
  }

  /// 获取当前通过存储通道注册的设备，供 WS 断线时统一收口本地连接态。
  Set<String> getDevIdsByStorage() {
    final list = _devProtocols.entries.where((item) => !item.value.isSocket);
    return list.map((item) => item.key.guid).toSet();
  }

  TransportProtocol? getProtocol(String devId) {
    var dev = _devProtocols.keys
        .where((item) => item.guid == devId)
        .firstOrNull;
    if (dev == null) {
      return null;
    }
    return _devProtocols[dev]!;
  }

  void addDevice(BaseDeviceInfo devInfo, TransportProtocol protocol) {
    _devProtocols[devInfo] = protocol;
  }

  void removeDevice(String devId) {
    _devProtocols.removeWhere((dev, _) => dev.guid == devId);
  }
}
