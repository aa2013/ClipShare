/// 设备未连接异常，携带设备 id 便于日志定位。
class DeviceNotConnectedException implements Exception {
  /// 未连接的设备 id
  final String devId;

  DeviceNotConnectedException(this.devId);

  @override
  String toString() => 'DeviceNotConnectedException: devId=$devId';
}