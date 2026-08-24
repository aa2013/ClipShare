import 'package:clipshare/shared/enums/rule/rule_content_type.dart';
import 'package:clipshare/shared/enums/rule/rule_script_language.dart';
import 'package:clipshare/shared/enums/rule/rule_trigger.dart';
import 'package:clipshare/shared/enums/rule/white_black_mode.dart';
import 'package:clipshare/shared/enums/support_platform.dart';
import 'package:clipshare/shared/extensions/string_extension.dart';
import 'package:clipshare/shared/models/rule/rule_item.dart';
import 'package:clipshare/shared/models/rule/rule_regex_content.dart';
import 'package:clipshare/shared/models/rule/rule_script_content.dart';

import '../app_database.dart';

export '../app_database.dart' show Rule;

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
  /// 深拷贝规则，沿用 Drift 生成的 JSON 字段名和全局 ValueSerializer。
  Rule copy() => Rule.fromJson(toJson());
  RuleItem toModel(){
    return RuleItem(
      id: id,
      version: version,
      name: name,
      platforms: platforms.split(',').where((e) => e.isNotNullAndEmpty).map((e) => SupportPlatForm.getValue(e)).toSet(),
      sources: sources.split(',').where((e) => e.isNotNullAndEmpty).toSet(),
      trigger: RuleTrigger.values.byName(trigger),
      type: RuleContentType.values.byName(type),
      regex: RuleRegexContent(
          mainRegex: regexMain,
          allowExtractData: regexAllowExtractData,
          extractRegex: regexExtractedContent,
          allowAddTag: regexAllowAddTag,
          tags: regexTags.split(',').where((e) => e.isNotNullAndEmpty).toSet(),
          preventSync: regexIsSyncDisabled,
          isFinal: regexIsFinalRule,
          mode: WhiteBlackMode.values.byName(regexWhiteBlackMode ?? WhiteBlackMode.defaultMode.name)
      ),
      script: RuleScriptContent(
        language: RuleScriptLanguage.getValue(scriptLanguage),
        content: scriptContent,
      ),
      enabled: enabled,
      order: order,
    );
  }
}
