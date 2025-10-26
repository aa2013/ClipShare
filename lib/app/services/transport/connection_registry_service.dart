import 'package:clipshare/app/data/enums/transport_protocol.dart';
import 'package:clipshare/app/data/models/dev_info.dart';
import 'package:clipshare/app/listeners/dev_alive_listener.dart';
import 'package:clipshare/app/listeners/discover_listener.dart';
import 'package:clipshare/app/listeners/forward_status_listener.dart';
import 'package:get/get.dart';

class DeviceConnectionRegistry {
  final Map<DevInfo, TransportProtocol> _devices;
  final List<DevAliveListener> _devAliveListeners;
  final List<DiscoverListener> _discoverListeners;
  final List<ForwardStatusListener> _forwardStatusListener;

  List<DevAliveListener> get devAliveListeners => List.from(_devAliveListeners, growable: false);

  List<DiscoverListener> get discoverListeners => List.from(_discoverListeners, growable: false);

  List<ForwardStatusListener> get forwardStatusListener => List.from(_forwardStatusListener, growable: false);

  DeviceConnectionRegistry(
    this._devices,
    this._devAliveListeners,
    this._discoverListeners,
    this._forwardStatusListener,
  );

  bool hasDevice(String devId) {
    return _devices.keys.where((item) => item.guid == devId).isNotEmpty;
  }

  TransportProtocol? getProtocol(String devId) {
    var dev = _devices.keys.where((item) => item.guid == devId).firstOrNull;
    if (dev == null) {
      return null;
    }
    return _devices[dev]!;
  }

  void addDevice(DevInfo devInfo, TransportProtocol protocol) {
    _devices[devInfo] = protocol;
  }

  void removeDevice(String devId) {
    _devices.removeWhere((dev, _) => dev.guid == devId);
  }
}

///设备连接注册服务
///管理所有已连接设备的信息（包括协议类型）
class ConnectionRegistryService extends GetxService {
  final _devices = <DevInfo, TransportProtocol>{};
  final List<DevAliveListener> _devAliveListeners = List.empty(growable: true);
  final List<DiscoverListener> _discoverListeners = List.empty(growable: true);
  final List<ForwardStatusListener> _forwardStatusListener = List.empty(growable: true);
  DeviceConnectionRegistry? _registry;

  DeviceConnectionRegistry get registry {
    if (_registry != null) {
      final t = _registry;
      _registry = null;
      return t!;
    }
    throw 'Registry can only be taken once';
  }

  ConnectionRegistryService() {
    _registry = DeviceConnectionRegistry(
      _devices,
      _devAliveListeners,
      _discoverListeners,
      _forwardStatusListener,
    );
  }

  ///添加设备连接监听
  void addDevAliveListener(DevAliveListener listener) {
    _devAliveListeners.add(listener);
  }

  ///移除设备连接监听
  void removeDevAliveListener(DevAliveListener listener) {
    _devAliveListeners.remove(listener);
  }

  ///添加设备发现监听
  void addDiscoverListener(DiscoverListener listener) {
    _discoverListeners.add(listener);
  }

  ///移除设备发现监听
  void removeDiscoverListener(DiscoverListener listener) {
    _discoverListeners.remove(listener);
  }

  ///添加中转连接状态监听
  void addForwardStatusListener(ForwardStatusListener listener) {
    _forwardStatusListener.add(listener);
  }

  ///移除中转连接状态监听
  void removeForwardStatusListener(ForwardStatusListener listener) {
    _forwardStatusListener.remove(listener);
  }
}
