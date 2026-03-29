import 'package:clipshare/app/data/enums/rule/rule_content_type.dart';
import 'package:clipshare/app/utils/extensions/string_extension.dart';
import 'package:floor/floor.dart';
import 'dart:convert';

@entity
class Rule {
  /// 主键，雪花 id
  @PrimaryKey(autoGenerate: false)
  int id;

  /// 规则名称
  String name;

  /// 支持平台，对应 [SupportPlatForm]，以 ',' 分割
  String platforms;

  /// 来源，以 ',' 分割
  String sources;

  /// 触发时机，对应 [RuleTrigger]
  String trigger;

  /// 规则类型，对应 [RuleContentType]
  String type;

  // region 正则规则，对应 [RuleRegexContent]

  /// 黑白名单模式
  String? regexWhiteBlackMode;

  /// 主识别正则
  String regexMain;

  /// 启用数据提取
  bool regexAllowExtractData;

  /// 数据提取正则
  String regexExtractedContent;

  /// 允许匹配后增加标签
  bool regexAllowAddTag;

  /// 增加的标签，以 ',' 分割，标签内容不可包含 ','
  String regexTags;

  /// 匹配后是否阻止同步
  bool regexIsSyncDisabled;

  /// 是否是最终规则
  bool regexIsFinalRule;

  // endregion

  // region 脚本规则

  ///脚本语言
  String scriptLanguage;

  ///脚本内容
  String scriptContent;

  // endregion

  /// 版本号
  int version;

  /// 是否启用
  bool enabled;

  /// 序号，排序依据
  int order;

  Rule({
    required this.id,
    required this.name,
    required this.platforms,
    this.sources = "",
    required this.trigger,
    required this.type,
    this.regexWhiteBlackMode,
    required this.regexMain,
    this.regexAllowExtractData = false,
    this.regexExtractedContent = "",
    this.regexAllowAddTag = false,
    this.regexTags = "",
    this.regexIsSyncDisabled = false,
    this.regexIsFinalRule = false,
    this.scriptLanguage = "lua",
    this.scriptContent = "",
    required this.version,
    this.enabled = false,
    required this.order,
  }) {
    //规则模式
    if (RuleContentType.regex.name.equalsIgnoreCase(type)) {
      assert(regexMain.isNotNullAndEmpty);
      if (regexAllowExtractData) {
        assert(regexExtractedContent.isNotNullAndEmpty);
      }
    } else {
      assert(scriptContent.isNotNullAndEmpty);
    }
  }

  /// 从 JSON Map 创建 Rule 实例
  factory Rule.fromJson(Map<String, dynamic> json) {
    return Rule(
      id: json['id'] as int,
      name: json['name'] as String,
      platforms: json['platforms'] as String,
      sources: json['sources'] as String,
      trigger: json['trigger'] as String,
      type: json['type'] as String,
      regexWhiteBlackMode: json['regexWhiteBlackMode'] as String?,
      regexMain: json['regexMain'] as String,
      regexAllowExtractData: json['regexAllowExtractData'] as bool,
      regexExtractedContent: json['regexExtractedContent'] as String,
      regexAllowAddTag: json['regexAllowAddTag'] as bool,
      regexTags: json['regexTags'] as String,
      regexIsSyncDisabled: json['regexIsSyncDisabled'] as bool,
      regexIsFinalRule: json['regexIsFinalRule'] as bool,
      scriptLanguage: json['language'] as String,
      scriptContent: json['content'] as String,
      version: json['version'] as int,
      enabled: json['enabled'] as bool,
      order: json['order'] as int,
    );
  }

  /// 转换为 JSON Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'platforms': platforms,
      'sources': sources,
      'trigger': trigger,
      'type': type,
      'regexWhiteBlackMode': regexWhiteBlackMode,
      'regexMain': regexMain,
      'regexAllowExtractData': regexAllowExtractData,
      'regexExtractedContent': regexExtractedContent,
      'regexAllowAddTag': regexAllowAddTag,
      'regexTags': regexTags,
      'regexIsSyncDisabled': regexIsSyncDisabled,
      'regexIsFinalRule': regexIsFinalRule,
      'language': scriptLanguage,
      'content': scriptContent,
      'version': version,
      'enabled': enabled,
      'order': order,
    };
  }

  @override
  String toString() => jsonEncode(toJson());
}
