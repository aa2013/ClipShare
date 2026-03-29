import 'dart:convert';

import 'package:floor/floor.dart';

@entity
class LuaLib {
  @PrimaryKey(autoGenerate: false)
  String libName;
  String displayName;
  String source;
  int version;

  LuaLib({
    required this.libName,
    required this.displayName,
    required this.source,
    required this.version,
  });

  factory LuaLib.fromJson(Map<String, dynamic> json) {
    return LuaLib(
      libName: json["libName"],
      displayName: json["displayName"],
      source: json["source"],
      version: json["version"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "libName": libName,
      "displayName": displayName,
      "source": source,
      "version": version,
    };
  }

  @override
  String toString() {
    return jsonEncode(this);
  }
}
