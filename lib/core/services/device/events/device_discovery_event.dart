/// 设备发现事件基类
sealed class DeviceDiscoveryEvent {
  const DeviceDiscoveryEvent();
}

/// 发现开始
class DeviceDiscoveryStarted extends DeviceDiscoveryEvent {
  const DeviceDiscoveryStarted();
}

/// 发现结束
class DeviceDiscoveryFinished extends DeviceDiscoveryEvent {
  const DeviceDiscoveryFinished();
}