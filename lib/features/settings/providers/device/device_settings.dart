import 'package:clipshare/features/settings/providers/device/device_paried_filter_status.dart';

import 'devicce_id_generate_way.dart';

class DeviceSettings {
  ///是否是首次启动
  final bool firstSetup;

  ///Android id 生成方式
  final DeviceIdGenerateWay androidIdGenerateWay;

  ///设备页面过滤类别
  final DevicePairedStatusFilter pairedStatusFilter;

  const DeviceSettings({
    this.firstSetup = true,
    this.androidIdGenerateWay = DeviceIdGenerateWay.unknown,
    this.pairedStatusFilter = DevicePairedStatusFilter.all,
  });
}
