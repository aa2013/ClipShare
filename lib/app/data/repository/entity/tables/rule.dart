import 'package:clipshare/app/data/enums/rule/rule_trigger.dart';
import 'package:clipshare/app/data/enums/white_black_mode.dart';

import '../../db/app_database.dart';

export '../../db/app_database.dart' show Rule;

/// 从旧同步/备份 JSON 还原规则，兼容脚本字段使用 language/content 的历史载荷。
Rule ruleFromJson(Map<String, dynamic> json) {
  return Rule(
    id: json['id'] as int,
    name: json['name'] as String,
    platforms: json['platforms'] as String,
    sources: json['sources'] as String? ?? '',
    trigger: json['trigger'] as String,
    type: json['type'] as String,
    regexWhiteBlackMode: json['regexWhiteBlackMode'] as String? ?? '',
    regexMain: json['regexMain'] as String,
    regexAllowExtractData: json['regexAllowExtractData'] as bool,
    regexExtractedContent: json['regexExtractedContent'] as String,
    regexAllowAddTag: json['regexAllowAddTag'] as bool,
    regexTags: json['regexTags'] as String,
    regexIsSyncDisabled: json['regexIsSyncDisabled'] as bool,
    regexIsFinalRule: json['regexIsFinalRule'] as bool,
    scriptLanguage: (json['language'] ?? json['scriptLanguage']) as String,
    scriptContent: (json['content'] ?? json['scriptContent']) as String,
    version: json['version'] as int,
    enabled: json['enabled'] as bool,
    order: json['order'] as int,
  );
}

/// 构造空规则占位，供缺失数据同步删除流程使用。
Rule emptyRule() {
  return Rule(
    id: 0,
    name: '',
    platforms: '',
    sources: '',
    trigger: RuleTrigger.onCopy.name,
    type: '',
    regexMain: '',
    version: 0,
    order: 0,
    regexWhiteBlackMode: WhiteBlackMode.defaultMode.name,
    regexAllowExtractData: false,
    regexExtractedContent: '',
    regexAllowAddTag: false,
    regexTags: '',
    regexIsSyncDisabled: false,
    regexIsFinalRule: false,
    scriptLanguage: 'lua',
    scriptContent: '',
    enabled: false,
  );
}

/// 规则行对象的业务扩展，真实数据类由 Drift 生成。
extension RuleExt on Rule {
  /// 旧同步载荷使用 language/content，不能直接依赖 Drift 的字段名序列化。
  Map<String, dynamic> toLegacyJson() {
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

  /// 深拷贝规则并保留旧 JSON 兼容字段。
  Rule copy() => ruleFromJson(toLegacyJson());
}
