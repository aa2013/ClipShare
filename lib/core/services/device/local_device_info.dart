import 'dart:convert';

import 'package:clipshare/core/database/app_database.dart';
import 'package:clipshare/core/database/tables/device.dart';
import 'package:clipshare/shared/enums/device_id_generate_way.dart';
import 'package:clipshare/shared/extensions/platform_extension.dart';
import 'package:clipshare/shared/models/version.dart';

class BaseDeviceInfo {
  final String guid;
  final String name;
  final PlatformType type;

  const BaseDeviceInfo({
    required this.guid,
    required this.name,
    required this.type,
  });

  factory BaseDeviceInfo.fromJson(Map<String, dynamic> map) {
    String guid = map['guid'];
    String name = map['name'];
    String type = map['type'];
    return BaseDeviceInfo(
      guid: guid,
      name: name,
      type: PlatformType(type),
    );
  }

  factory BaseDeviceInfo.fromDevice(Device device) {
    return BaseDeviceInfo(
      guid: device.guid,
      name: device.devName,
      type: PlatformType(device.type),
    );
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }

  Map<String, dynamic> toJson() {
    return {
      'guid': guid,
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

  ///Android id 生成方式（一次性确定后固定，不随配置变化）
  final Device self;

  const LocalDeviceInfo({
    required this.baseDeviceInfo,
    required this.appVersion,
    required this.androidOsVersion,
    required this.localName,
    required this.self,
    this.firstSetup = true,
    this.androidIdGenerateWay = DeviceIdGenerateWay.unknown,
  });
}
