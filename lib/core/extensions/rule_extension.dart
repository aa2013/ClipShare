import 'package:clipshare/core/database/tables/rule.dart';
import 'package:clipshare/shared/models/rule/rule_item.dart';

extension RuleItemExt on RuleItem{
  Rule toRule() {
    return Rule(
      id: id,
      name: name,
      platforms: platforms.join(','),
      sources: sources.join(','),
      trigger: trigger.name,
      type: type.name,
      regexWhiteBlackMode: regex.mode.name,
      regexMain: regex.mainRegex,
      regexAllowExtractData: regex.allowExtractData,
      regexExtractedContent: regex.extractRegex,
      regexAllowAddTag: regex.allowAddTag,
      regexTags: regex.tags.join(','),
      regexIsSyncDisabled: regex.preventSync,
      regexIsFinalRule: regex.isFinal,
      scriptLanguage: script.language.name,
      scriptContent: script.content,
      version: version,
      enabled: enabled,
      order: order,
    );
  }
}