import 'dart:convert';

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

  const LocalDeviceInfo({
    required this.baseDeviceInfo,
    required this.appVersion,
    required this.androidOsVersion,
    required this.localName,
  });
}
