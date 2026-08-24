import 'dart:convert';

import 'package:clipshare/shared/enums/device_id_generate_way.dart';
import 'package:clipshare/shared/extensions/platform_extension.dart';
import 'package:clipshare/shared/models/version.dart';

class BaseDeviceInfo {
  final String id;
  final String name;
  final PlatformType type;

  const BaseDeviceInfo({
    required this.id,
    required this.name,
    required this.type,
  });

  @override
  String toString() {
    return jsonEncode(toJson());
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
    };
  }
}

class LocalDeviceInfo {
  ///本机基础设备信息
  final BaseDeviceInfo baseDeviceInfo;

  ///app版本
  final AppVersion appVersion;

  ///Android 系统版本
  final double androidOsVersion;

  ///本机设备名称
  final String localName;

  ///是否是首次启动（一次性确定后固定，不随配置变化）
  final bool firstSetup;

  ///Android id 生成方式（一次性确定后固定，不随配置变化）
  final DeviceIdGenerateWay androidIdGenerateWay;

  const LocalDeviceInfo({
    required this.baseDeviceInfo,
    required this.appVersion,
    required this.androidOsVersion,
    required this.localName,
    this.firstSetup = true,
    this.androidIdGenerateWay = DeviceIdGenerateWay.unknown,
  });
}
