import 'dart:convert';

import 'package:clipshare/app/data/enums/rule/rule_script_language.dart';
import 'package:floor/floor.dart';

@entity
class LuaLib {
  @PrimaryKey(autoGenerate: false)
  String libName;
  String displayName;
  String language;
  String source;
  int version;
  @ignore
  bool isNewData;

  RuleScriptLanguage get scriptLanguage {
    return RuleScriptLanguage.getValue(language);
  }

  LuaLib({
    required this.libName,
    required this.displayName,
    required this.language,
    required this.source,
    required this.version,
    this.isNewData = false,
  });

  factory LuaLib.fromJson(Map<String, dynamic> json) {
    return LuaLib(
      libName: json["libName"],
      displayName: json["displayName"],
      language: json["language"],
      source: json["source"],
      version: json["version"],
      isNewData: json["isNewData"],
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is LuaLib &&
            runtimeType == other.runtimeType &&
            libName == other.libName &&
            displayName == other.displayName &&
            language == other.language &&
            source == other.source &&
            version == other.version;
  }

  @override
  int get hashCode {
    return Object.hash(libName, displayName, language, source, version);
  }

  Map<String, dynamic> toJson() {
    return {
      "libName": libName,
      "displayName": displayName,
      "language": language,
      "source": source,
      "version": version,
      "isNewData": isNewData,
    };
  }

  @override
  String toString() {
    return jsonEncode(this);
  }
}
