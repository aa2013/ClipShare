import 'dart:convert';
import 'dart:typed_data';

import 'package:floor/floor.dart';

///app信息
@Entity(
  indices: [
    Index(value: ['appId', "devId"], unique: true),
  ],
)
class AppInfo {
  ///主键，雪花 id
  @PrimaryKey(autoGenerate: false)
  int id;

  ///在Android上是包名
  String appId;

  ///设备id
  String devId;

  ///应用名称
  String name;

  ///icon
  String iconB64;

  AppInfo({
    required this.id,
    required this.appId,
    required this.devId,
    required this.name,
    required this.iconB64,
  });

  factory AppInfo.fromJson(Map<String, dynamic> map) {
    return AppInfo(
      id: map["id"],
      appId: map["appId"],
      devId: map["devId"],
      name: map["name"],
      iconB64: map["iconB64"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "appId": appId,
      "devId": devId,
      "name": name,
      "iconB64": iconB64,
    };
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }

  @override
  bool operator ==(Object other) => identical(this, other) || other is AppInfo && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

extension AppInfoExt on AppInfo {
  Uint8List get iconBytes => base64.decode(iconB64);
}
