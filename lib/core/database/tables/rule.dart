import 'package:clipshare/shared/enums/rule/rule_trigger.dart';
import 'package:clipshare/shared/enums/rule/white_black_mode.dart';

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
}
