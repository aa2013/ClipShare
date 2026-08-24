import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';

import 'src/default_text_style_font_rule.dart';
import 'src/dependency_direction_rule.dart';

/// Plugin entry point instance, loaded by the Dart analysis server.
final plugin = DependencyLintPlugin();

/// Plugin that validates clipshare's layered dependency direction.
class DependencyLintPlugin extends Plugin {
  @override
  String get name => 'clipshare_dependency_lint';

  @override
  void register(PluginRegistry registry) {
    // `registerWarningRule` is a framework term meaning "enabled by default";
    // it does not control the diagnostic severity. The severity comes from each
    // rule's own LintCode (both are ERROR here), so these rules run under
    // `flutter analyze` without extra configuration and are reported as errors.
    registry.registerWarningRule(DependencyDirectionRule());
    // Disallow a raw TextStyle replacing DefaultTextStyle/AnimatedDefaultTextStyle,
    // which would drop the theme font.
    registry.registerWarningRule(DefaultTextStyleFontRule());
  }
}
