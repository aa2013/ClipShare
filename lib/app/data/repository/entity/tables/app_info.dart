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

  ///判断内容是否相同（不含id）
  ///场景：当app更新等情况导致图标变化，就需要做更新操作
  bool hasSameContent(AppInfo? appInfo) {
    if (appInfo == null) return false;
    return appInfo.appId == appId && appInfo.devId == devId && appInfo.name == name && appInfo.iconB64 == iconB64;
  }

  @override
  bool operator ==(Object other) => identical(this, other) || other is AppInfo && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

extension AppInfoExt on AppInfo {
  static final Map<int, Uint8List> _bytes = {};

  static void removeWhere(bool Function(int, Uint8List) func) {
    return _bytes.removeWhere(func);
  }

  Uint8List get iconBytes {
    if (!_bytes.containsKey(id)) {
      _bytes[id] = base64.decode(iconB64);
    }
    return _bytes[id]!;
  }
}
