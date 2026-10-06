import 'package:clipshare/core/services/device/local_device_info.dart';
import 'package:clipshare/shared/enums/transport_protocol.dart';
import 'package:clipshare/shared/models/version.dart';

/// 设备生命周期事件基类
sealed class DeviceLifecycleEvent {
  const DeviceLifecycleEvent();
}

/// 连接成功
class DeviceConnected extends DeviceLifecycleEvent {
  final BaseDeviceInfo device;
  final AppVersion minVersion;
  final AppVersion version;
  final TransportProtocol protocol;

  const DeviceConnected({
    required this.device,
    required this.minVersion,
    required this.version,
    required this.protocol,
  });
}

/// 断开连接
class DeviceDisconnected extends DeviceLifecycleEvent {
  final String deviceId;

  const DeviceDisconnected(this.deviceId);
}

/// 配对成功
class DevicePaired extends DeviceLifecycleEvent {
  final BaseDeviceInfo device;
  final bool result;
  final String? address;

  const DevicePaired({
    required this.device,
    required this.result,
    this.address,
  });
}

/// 取消配对
class DevicePairingCanceled extends DeviceLifecycleEvent {
  final BaseDeviceInfo device;

  const DevicePairingCanceled(this.device);
}

/// 忘记设备
class DeviceForgotten extends DeviceLifecycleEvent {
  final BaseDeviceInfo device;

  const DeviceForgotten(this.device);
}
