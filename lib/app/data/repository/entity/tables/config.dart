import 'dart:convert';

import 'package:floor/floor.dart';

@entity
class Config {
  ///配置项
  @primaryKey
  late String key;

  ///配置值
  late String value;

  ///用户 id
  late int uid;

  Config({
    required this.key,
    required this.value,
    required this.uid,
  });

  factory Config.fromJson(Map<String, dynamic> json) {
    return Config(
      key: json["key"],
      value: json["value"],
      uid: json["uid"],
    );
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }

  Map<String, dynamic> toJson() {
    return {
      "key": key,
      "value": value,
      "uid": uid,
    };
  }
}
