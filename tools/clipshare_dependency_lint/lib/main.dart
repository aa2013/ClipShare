import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';

import 'src/dependency_direction_rule.dart';

/// 插件入口实例，供 Dart 分析服务器加载。
final plugin = DependencyLintPlugin();

/// clipshare 依赖方向校验插件。
class DependencyLintPlugin extends Plugin {
  @override
  String get name => 'clipshare_dependency_lint';

  @override
  void register(PluginRegistry registry) {
    // 注册为 warning 规则：默认启用，无需额外配置即可在 flutter analyze 中报告。
    registry.registerWarningRule(DependencyDirectionRule());
  }
}
