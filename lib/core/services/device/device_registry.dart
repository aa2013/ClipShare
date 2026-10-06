
import 'package:clipshare/shared/enums/transport_protocol.dart';
import 'package:clipshare/shared/models/version.dart';

import 'local_device_info.dart';

/// 设备注册中心
class DeviceRegistry {
  /// 已连接设备的协议，设备基础信息 -> 协议
  final Map<BaseDeviceInfo, TransportProtocol> _devProtocols = {};

  /// 已连接设备的协议，设备基础信息 -> 版本号
  final Map<BaseDeviceInfo, AppVersion> _devVersions = {};

  /// 已连接设备的协议，设备基础信息 -> 最低版本号
  final Map<BaseDeviceInfo, AppVersion> _devMinVersions = {};

  DeviceRegistry();

  bool hasDevice(String devId) {
    return _devProtocols.keys
        .where((item) => item.guid == devId)
        .isNotEmpty;
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

  AppVersion? getMinVersion(String devId) {
    var dev = _devMinVersions.keys
        .where((item) => item.guid == devId)
        .firstOrNull;
    if (dev == null) {
      return null;
    }
    return _devMinVersions[dev]!;
  }

  AppVersion? getVersion(String devId) {
    var dev = _devVersions.keys
        .where((item) => item.guid == devId)
        .firstOrNull;
    if (dev == null) {
      return null;
    }
    return _devVersions[dev]!;
  }

  void addDevice(BaseDeviceInfo devInfo, TransportProtocol protocol, AppVersion version, AppVersion minVersion) {
    _devProtocols[devInfo] = protocol;
    _devVersions[devInfo] = version;
    _devMinVersions[devInfo] = minVersion;
  }

  void removeDevice(String devId) {
    _devProtocols.removeWhere((dev, _) => dev.guid == devId);
    _devVersions.removeWhere((dev, _) => dev.guid == devId);
    _devMinVersions.removeWhere((dev, _) => dev.guid == devId);
  }
}
