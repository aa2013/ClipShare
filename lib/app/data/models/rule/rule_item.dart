import 'dart:convert';

import 'package:clipshare/app/data/enums/rule/rule_category.dart';
import 'package:clipshare/app/data/enums/rule/rule_content_type.dart';
import 'package:clipshare/app/data/enums/rule/rule_trigger.dart';
import 'package:clipshare/app/data/enums/support_platform.dart';

import 'rule_regex_content.dart';
import 'rule_script_content.dart';

class RuleItem {
  int version;
  final String id;
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
  });

  factory RuleItem.fromJson(Map<String, dynamic> json) {
    return RuleItem(
      id: json['id'] as String,
      version: json['version'] as int,
      name: json['name'] as String,
      category: RuleCategory.values.byName(
        json['category'] as String,
      ),
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
      allowSync: json['allowSync'] as bool,
      enabled: json['enabled'] as bool,
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
    };
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }

  RuleItem copy() {
    return RuleItem.fromJson(jsonDecode(jsonEncode(this)));
  }
}
