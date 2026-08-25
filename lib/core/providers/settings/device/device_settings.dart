import 'package:clipshare/core/providers/settings/device/device_paried_filter_status.dart';

class DeviceSettings {
  ///设备页面过滤类别
  final DevicePairedStatusFilter pairedStatusFilter;

  ///加密密钥
  final String? dhAesKey;

  ///自定义设备名称
  final String? customName;

  const DeviceSettings({
    this.pairedStatusFilter = DevicePairedStatusFilter.all,
    this.dhAesKey,
    this.customName,
  });
}
