import 'package:clipshare/core/services/rules/models/rule_state.dart';
import 'package:clipshare/shared/enums/rule/rule_content_type.dart';
import 'package:clipshare/shared/enums/rule/rule_script_language.dart';
import 'package:clipshare/shared/enums/rule/rule_trigger.dart';
import 'package:clipshare/shared/enums/rule/white_black_mode.dart';
import 'package:clipshare/shared/models/rule/rule_item.dart';
import 'package:clipshare/shared/models/rule/rule_regex_content.dart';
import 'package:clipshare/shared/models/rule/rule_script_content.dart';
import 'package:flutter_test/flutter_test.dart';

///构造仅用于规则状态判定的最小规则项。
RuleItem _createRule({
  required int id,
  required RuleTrigger trigger,
  required bool enabled,
}) {
  return RuleItem(
    id: id,
    version: 1,
    name: 'rule-$id',
    platforms: const {},
    sources: const {},
    trigger: trigger,
    type: RuleContentType.regex,
    regex: RuleRegexContent(
      mode: WhiteBlackMode.defaultMode,
      mainRegex: '',
      allowExtractData: false,
      extractRegex: '',
      allowAddTag: false,
      tags: const {},
      preventSync: false,
      isFinal: false,
    ),
    script: RuleScriptContent(
      language: RuleScriptLanguage.lua,
      content: '',
    ),
    enabled: enabled,
    order: id,
  );
}

RuleState _createState(List<RuleItem> rules) {
  return RuleState(
    rules: rules,
    scriptModules: const [],
  );
}

void main() {
  group('RuleState.enableSmsSync', () {
    test('存在启用中的短信规则时返回 true', () {
      final state = _createState([
        _createRule(id: 1, trigger: RuleTrigger.onSms, enabled: true),
      ]);

      expect(state.enableSmsSync, isTrue);
    });

    test('短信规则全部停用时返回 false', () {
      final state = _createState([
        _createRule(id: 1, trigger: RuleTrigger.onSms, enabled: false),
      ]);

      expect(state.enableSmsSync, isFalse);
    });

    test('仅启用非短信规则时返回 false', () {
      final state = _createState([
        _createRule(id: 1, trigger: RuleTrigger.onCopy, enabled: true),
        _createRule(id: 2, trigger: RuleTrigger.onNotification, enabled: true),
      ]);

      expect(state.enableSmsSync, isFalse);
    });

    test('规则列表为空时返回 false', () {
      final state = _createState([]);

      expect(state.enableSmsSync, isFalse);
    });
  });
}
