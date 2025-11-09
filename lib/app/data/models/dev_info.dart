import 'dart:convert';

import '../repository/entity/tables/device.dart';

class DevInfo {
  String guid;
  String name;
  String type;

  DevInfo(this.guid, this.name, this.type);

  static DevInfo fromDevice(Device dev) {
    return DevInfo(dev.guid, dev.devName, dev.type);
  }

  static DevInfo fromJson(Map<String, dynamic> map) {
    String guid = map["guid"];
    String name = map["name"];
    String type = map["type"];
    return DevInfo(guid, name, type);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DevInfo) return false;
    return guid == other.guid;
  }

  Map<String, dynamic> toJson() {
    return {
      "guid": guid,
      "name": name,
      "type": type,
    };
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }

  @override
  int get hashCode => guid.hashCode;
}
