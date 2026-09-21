import 'dart:convert';

import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/enums/rule/rule_content_type.dart';
import 'package:clipshare/shared/enums/rule/rule_trigger.dart';
import 'package:clipshare/shared/enums/support_platform.dart';
import 'package:clipshare/shared/extensions/string_extension.dart';

import 'rule_regex_content.dart';
import 'rule_script_content.dart';

class RuleItem implements Comparable<RuleItem> {
  int version;
  final int id;
  String name;
  Set<SupportPlatForm> platforms;
  Set<String> sources;
  RuleTrigger trigger;
  RuleContentType type;
  RuleRegexContent regex;
  RuleScriptContent script;
  bool enabled;
  int order;
  bool isNewData;

  ///标记是否脏数据需要保存数据库
  bool dirty;

  bool get isUseScript => type == RuleContentType.script;

  bool get isUseRegex => type == RuleContentType.regex;

  RuleItem({
    required this.id,
    required this.version,
    required this.name,
    required this.platforms,
    required this.sources,
    required this.trigger,
    required this.type,
    required this.regex,
    required this.script,
    required this.enabled,
    required this.order,
    this.dirty = false,
    this.isNewData = false,
  });

  factory RuleItem.fromJson(Map<String, dynamic> json) {
    return RuleItem(
      id: json['id'] as int,
      version: json['version'] as int,
      name: json['name'] as String,
      platforms: (json['platforms'] as List<dynamic>).map((e) => SupportPlatForm.values.byName(e as String)).toSet(),
      sources: (json['sources'] as List<dynamic>).map((e) => e as String).toSet(),
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
      enabled: json['enabled'] as bool,
      order: json['order'] as int,
      dirty: json['dirty'] as bool,
      isNewData: json['isNewData'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    final platformNames = platforms.map((e) => e.name).toList()..sort();
    return {
      'id': id,
      'version': version,
      'name': name,
      'platforms': platformNames,
      'sources': sources.toList()..sort(),
      'trigger': trigger.name,
      'type': type.name,
      'regex': regex.toJson(),
      'script': script.toJson(),
      'enabled': enabled,
      'order': order,
      'dirty': dirty,
      'isNewData': isNewData,
    };
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
        return TranslationKey.ruleItemContentRequired.tr;
      }
      if (regex.allowExtractData && regex.extractRegex.isNullOrEmpty) {
        return TranslationKey.ruleItemExtractRuleRequired.tr;
      }
    } else if (type == RuleContentType.script) {
      if (script.content.trim().isNullOrEmpty) {
        return TranslationKey.ruleItemScriptContentRequired.tr;
      }
    } else {
      return TranslationKey.ruleItemUnsupportedOperation.tr;
    }
    return null;
  }

  @override
  int compareTo(other) {
    return order - other.order;
  }
}
