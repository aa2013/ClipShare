import 'package:clipshare/core/database/app_database.dart';
import 'package:clipshare/shared/enums/rule/rule_trigger.dart';
import 'package:clipshare/shared/models/rule/rule_item.dart';

class RuleState {
  final List<RuleItem> rules;
  final List<ScriptModule> scriptModules;
  final RuleItem? selectedRuleItem;
  final ScriptModule? selectedLuaModuleItem;
  final bool activeItemChanged;

  ///是否存在启用中的短信规则
  ///
  ///短信读取权限仅在启用短信规则后才需要，权限设置项据此决定是否展示。
  bool get enableSmsSync => hasEnabledSmsRule(rules);

  ///判断规则列表中是否存在启用中的短信规则。
  ///
  ///规则状态在初始化前尚未写入 [RuleState]，执行器侧也需要同一判定，
  ///因此提取为静态方法供两处复用，避免规则条件出现分歧。
  static bool hasEnabledSmsRule(Iterable<RuleItem> rules) {
    return rules.any((rule) => rule.trigger == RuleTrigger.onSms && rule.enabled);
  }

  const RuleState({
    required this.rules,
    required this.scriptModules,
    this.selectedRuleItem,
    this.selectedLuaModuleItem,
    this.activeItemChanged = false,
  });

  RuleState copyWith({
    List<RuleItem>? rules,
    List<ScriptModule>? scriptModules,
    RuleItem? selectedRuleItem,
    ScriptModule? selectedLuaModuleItem,
  }) {
    return RuleState(
      rules: rules ?? List.from(this.rules, growable: false),
      scriptModules: scriptModules ?? List.from(this.scriptModules, growable: false),
      selectedRuleItem: selectedRuleItem ?? this.selectedRuleItem,
      selectedLuaModuleItem: selectedLuaModuleItem ?? this.selectedLuaModuleItem,
    );
  }
}
