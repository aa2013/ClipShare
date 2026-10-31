import 'device_connect_exception.dart';

/// 未配对设备被本机“可被发现”准入策略拒绝。
class UnpairedDeviceRejectedException extends DeviceConnectException {
  /// 被拒绝的远端设备 id。
  final String devId;

  UnpairedDeviceRejectedException(this.devId)
      : super('Unpaired device discovery is disabled. devId=$devId');

  @override
  String toString() => 'UnpairedDeviceRejectedException: devId=$devId';
}
