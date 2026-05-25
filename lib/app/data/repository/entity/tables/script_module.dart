import 'dart:convert';

import 'package:clipshare/app/data/enums/rule/rule_script_language.dart';
import 'package:floor/floor.dart';

@entity
class ScriptModule {
  @PrimaryKey(autoGenerate: false)
  String moduleName;
  String displayName;
  @TypeConverters([RuleScriptLanguageConverter])
  RuleScriptLanguage language;
  String source;
  int version;
  @ignore
  bool isNewData;

  ScriptModule({
    required this.moduleName,
    required this.displayName,
    required this.language,
    required this.source,
    required this.version,
    this.isNewData = false,
  });

  factory ScriptModule.fromJson(Map<String, dynamic> json) {
    return ScriptModule(
      moduleName: json["moduleName"],
      displayName: json["displayName"],
      language: RuleScriptLanguage.getValue(json["language"]),
      source: json["source"],
      version: json["version"],
      isNewData: json["isNewData"],
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is ScriptModule && runtimeType == other.runtimeType && moduleName == other.moduleName && displayName == other.displayName && language == other.language && source == other.source && version == other.version;
  }

  @override
  int get hashCode {
    return Object.hash(moduleName, displayName, language, source, version);
  }

  Map<String, dynamic> toJson() {
    return {
      "moduleName": moduleName,
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

  static ScriptModule empty() {
    return ScriptModule(
      moduleName: '',
      displayName: '',
      language: RuleScriptLanguage.unknown,
      source: '',
      version: 0,
    );
  }

  ScriptModule copy() {
    return ScriptModule.fromJson(jsonDecode(jsonEncode(this)));
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
