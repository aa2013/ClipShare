import 'package:clipshare/core/database/app_database.dart';
import 'package:clipshare/shared/models/rule/rule_item.dart';

class RuleState {
  final List<RuleItem> rules;
  final List<ScriptModule> scriptModules;
  final RuleItem? selectedRuleItem;
  final ScriptModule? selectedLuaModuleItem;
  final bool activeItemChanged;

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
