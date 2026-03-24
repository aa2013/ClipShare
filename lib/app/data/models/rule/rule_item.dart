import 'dart:convert';

import 'package:clipshare/app/data/enums/rule/rule_category.dart';
import 'package:clipshare/app/data/enums/rule/rule_content_type.dart';
import 'package:clipshare/app/data/enums/rule/rule_script_language.dart';
import 'package:clipshare/app/data/enums/rule/rule_trigger.dart';
import 'package:clipshare/app/data/enums/support_platform.dart';
import 'package:clipshare/app/utils/extensions/string_extension.dart';

import '../../repository/entity/tables/rule.dart';
import 'rule_regex_content.dart';
import 'rule_script_content.dart';

class RuleItem {
  int version;
  final int id;
  String name;
  RuleCategory category;
  Set<SupportPlatForm> platforms;
  Set<String> sources;
  RuleTrigger trigger;
  RuleContentType type;
  RuleRegexContent regex;
  RuleScriptContent script;
  bool allowSync;
  bool enabled;
  int order;

  bool get isUseScript => type == RuleContentType.script;

  bool get isUseRegex => type == RuleContentType.regex;

  RuleItem({
    required this.id,
    required this.version,
    required this.name,
    required this.category,
    required this.platforms,
    required this.sources,
    required this.trigger,
    required this.type,
    required this.regex,
    required this.script,
    required this.allowSync,
    required this.enabled,
    required this.order,
  });

  factory RuleItem.fromJson(Map<String, dynamic> json) {
    return RuleItem(
      id: json['id'] as int,
      version: json['version'] as int,
      name: json['name'] as String,
      category: RuleCategory.values.byName(
        json['category'] as String,
      ),
      platforms: (json['platforms'] as List<dynamic>)
          .map((e) => SupportPlatForm.values.byName(e as String))
          .toSet(),
      sources: (json['sources'] as List<dynamic>)
          .map((e) => e as String)
          .toSet(),
      trigger: RuleTrigger.values.byName(
        json['trigger'] as String,
      ),
      type: RuleContentType.values.byName(
        json['type'] as String,
      ),
      regex: RuleRegexContent.fromJson(
        json['regex'] as Map<String, dynamic>,
      ),
      script: RuleScriptContent.fromJson(
        json['script'] as Map<String, dynamic>,
      ),
      allowSync: json['allowSync'] as bool,
      enabled: json['enabled'] as bool,
      order: json['order'] as int,
    );
  }

  factory RuleItem.fromRule(Rule rule) {
    return RuleItem(
      id: rule.id,
      version: rule.version,
      name: rule.name,
      category: RuleCategory.values.byName(rule.category),
      platforms: rule.platforms
          .split(",")
          .where((e) => e.isNotNullAndEmpty)
          .map((e) => SupportPlatForm.values.byName(e.lowerFirst))
          .toSet(),
      sources: rule.sources
          .split(",")
          .where((e) => e.isNotNullAndEmpty)
          .toSet(),
      trigger: RuleTrigger.values.byName(rule.trigger),
      type: RuleContentType.values.byName(rule.type),
      regex: RuleRegexContent(
        mainRegex: rule.regexMain,
        allowExtractData: rule.regexAllowExtractData,
        extractRegex: rule.regexExtract,
        allowAddTag: rule.regexAllowAddTag,
        tags: rule.regexTags
          .split(",")
          .where((e) => e.isNotNullAndEmpty)
          .toSet(),
        preventSync: rule.regexPreventSync,
        isFinal: rule.regexIsFinal,
      ),
      script: RuleScriptContent(
        language: RuleScriptLanguage.getValue(rule.scriptLanguage),
        content: rule.scriptContent,
      ),
      allowSync: rule.allowSync,
      enabled: rule.enabled,
      order: rule.order,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'version': version,
      'name': name,
      'category': category.name,
      'platforms': platforms.map((e) => e.name).toList(),
      'sources': sources.toList(),
      'trigger': trigger.name,
      'type': type.name,
      'regex': regex.toJson(),
      'script': script.toJson(),
      'allowSync': allowSync,
      'enabled': enabled,
      'order': order,
    };
  }

  Rule toRule() {
    return Rule(
      id: id,
      name: name,
      category: category.name,
      platforms: platforms.join(","),
      sources: sources.join(","),
      trigger: trigger.name,
      type: type.name,
      regexWhiteBlackMode: regex.mode?.name,
      regexMain: regex.mainRegex,
      regexAllowExtractData: regex.allowExtractData,
      regexExtract: regex.extractRegex,
      regexAllowAddTag: regex.allowAddTag,
      regexTags: regex.tags.join(","),
      regexPreventSync: regex.preventSync,
      regexIsFinal: regex.isFinal,
      scriptLanguage: script.language.name,
      scriptContent: script.content,
      version: version,
      allowSync: allowSync,
      enabled: enabled,
      order: order,
    );
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }

  RuleItem copy() {
    return RuleItem.fromJson(jsonDecode(jsonEncode(this)));
  }

  String? validate() {
    if (type == RuleContentType.regex) {
      if (regex.mainRegex.isNullOrEmpty) {
        return "规则内容不可为空";
      }
      if (regex.allowExtractData && regex.extractRegex.isNullOrEmpty) {
        return "内容提取规则不可为空";
      }
    } else if (type == RuleContentType.script) {
      if (script.content.trim().isNullOrEmpty) {
        return "脚本内容不可为空";
      }
    } else {
      return "不支持的操作";
    }
    return null;
  }
}
