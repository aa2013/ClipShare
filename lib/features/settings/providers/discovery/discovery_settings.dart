import 'package:clipshare/core/constants/network_constants.dart' as net;

class DiscoverySettings {
  ///设备发现端口
  final int port;

  ///允许be呗
  final bool allowDiscovery;

  ///仅中转模式（调试用）
  final bool onlyForwardMode;

  ///心跳间隔
  final int heartbeatInterval;

  ///是否屏幕关闭后自动断开所有链接
  final bool autoCloseConnAfterScreenOff;

  ///屏幕亮起时发现设备
  final bool enableAutoSyncOnScreenOpened;

  ///切网时保持连接
  final bool keepConnectionsOnNetworkSwitch;

  ///仅手动子网扫描
  final bool onlyManualDiscoverySubNet;

  ///设备发现排除网卡
  final List<String> noDiscoveryIfs;

  const DiscoverySettings({
    this.port = net.port,
    this.allowDiscovery = true,
    this.onlyForwardMode = false,
    this.heartbeatInterval = net.heartbeatInterval,
    this.autoCloseConnAfterScreenOff = false,
    this.enableAutoSyncOnScreenOpened = true,
    this.keepConnectionsOnNetworkSwitch = true,
    this.onlyManualDiscoverySubNet = true,
    this.noDiscoveryIfs = const [],
  });
}
