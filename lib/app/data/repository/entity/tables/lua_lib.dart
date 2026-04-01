import 'dart:convert';

import 'package:clipshare/app/data/enums/rule/rule_script_language.dart';
import 'package:floor/floor.dart';

@entity
class RuleLib {
  @PrimaryKey(autoGenerate: false)
  String libName;
  String displayName;
  @TypeConverters([RuleScriptLanguageConverter])
  RuleScriptLanguage language;
  String source;
  int version;
  @ignore
  bool isNewData;

  RuleLib({
    required this.libName,
    required this.displayName,
    required this.language,
    required this.source,
    required this.version,
    this.isNewData = false,
  });

  factory RuleLib.fromJson(Map<String, dynamic> json) {
    return RuleLib(
      libName: json["libName"],
      displayName: json["displayName"],
      language: RuleScriptLanguage.getValue(json["language"]),
      source: json["source"],
      version: json["version"],
      isNewData: json["isNewData"],
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is RuleLib && runtimeType == other.runtimeType && libName == other.libName && displayName == other.displayName && language == other.language && source == other.source && version == other.version;
  }

  @override
  int get hashCode {
    return Object.hash(libName, displayName, language, source, version);
  }

  Map<String, dynamic> toJson() {
    return {
      "libName": libName,
      "displayName": displayName,
      "language": language.name,
      "source": source,
      "version": version,
      "isNewData": isNewData,
    };
  }

  @override
  String toString() {
    return jsonEncode(this);
  }

  static RuleLib empty() {
    return RuleLib(
      libName: '',
      displayName: '',
      language: RuleScriptLanguage.unknown,
      source: '',
      version: 0,
    );
  }
}

// 枚举类型到String的转换器
class RuleScriptLanguageConverter extends TypeConverter<RuleScriptLanguage, String> {
  @override
  RuleScriptLanguage decode(String name) {
    return RuleScriptLanguage.getValue(name);
  }

  @override
  String encode(RuleScriptLanguage value) {
    return value.name;
  }
}
