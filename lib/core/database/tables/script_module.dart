import 'package:clipshare/shared/enums/rule/rule_script_language.dart';

import '../app_database.dart';

export '../app_database.dart' show ScriptModule;

final Expando<bool> _scriptModuleNewData = Expando<bool>('scriptModuleNewData');

/// 从 JSON 还原脚本模块，兼容 UI 临时字段 isNewData 不落库的设计。
ScriptModule scriptModuleFromJson(Map<String, dynamic> json) {
  final module = ScriptModule(
    moduleName: json['moduleName'],
    displayName: json['displayName'],
    language: RuleScriptLanguage.getValue(json['language']),
    source: json['source'],
    version: json['version'],
  );
  module.isNewData = json['isNewData'] as bool? ?? false;
  return module;
}

/// 构造空脚本模块占位，供缺失数据同步删除流程使用。
ScriptModule emptyScriptModule() {
  return const ScriptModule(
    moduleName: '',
    displayName: '',
    language: RuleScriptLanguage.unknown,
    source: '',
    version: 0,
  );
}

/// 脚本模块行对象的业务扩展，真实数据类由 Drift 生成。
extension ScriptModuleExt on ScriptModule {
  /// UI 新建状态不属于数据库物理字段，通过 Expando 绑定到运行时对象。
  bool get isNewData => _scriptModuleNewData[this] ?? false;

  /// 设置 UI 新建状态，保存入库时不会进入 Drift companion。
  set isNewData(bool value) => _scriptModuleNewData[this] = value;

  /// 深拷贝脚本模块，并保留 UI 新建状态。
  ScriptModule copy() {
    final module = ScriptModule(
      moduleName: moduleName,
      displayName: displayName,
      language: language,
      source: source,
      version: version,
    );
    module.isNewData = isNewData;
    return module;
  }
}
