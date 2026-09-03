import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

/// Rule that disallows a raw `TextStyle(...)` literal passed to the `style`
/// argument of `DefaultTextStyle` / `AnimatedDefaultTextStyle`.
///
/// A raw style replaces the inherited `DefaultTextStyle`, so descendant `Text`
/// widgets lose the theme font family (and other inherited text style fields).
/// Use `DefaultTextStyle.merge`, or derive the style from `Theme.textTheme` /
/// `DefaultTextStyle.of(context).style` instead.
class DefaultTextStyleFontRule extends AnalysisRule {
  static const code = LintCode(
    'default_text_style_font',
    'Avoid a raw TextStyle in DefaultTextStyle/AnimatedDefaultTextStyle; it drops the theme font.',
    correctionMessage:
        'Use DefaultTextStyle.merge, or derive from Theme.textTheme / DefaultTextStyle.of(context).style.',
    severity: DiagnosticSeverity.ERROR,
  );

  DefaultTextStyleFontRule()
    : super(
        name: 'default_text_style_font',
        description:
            'Disallow raw TextStyle in DefaultTextStyle/AnimatedDefaultTextStyle.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addInstanceCreationExpression(this, _Visitor(this));
  }
}

/// Reports raw `TextStyle(...)` styles that override the default text style.
class _Visitor extends SimpleAstVisitor<void> {
  final DefaultTextStyleFontRule rule;

  _Visitor(this.rule);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final typeElement = node.constructorName.type.element;
    if (typeElement is! InterfaceElement) {
      return;
    }
    final typeName = typeElement.name;
    final isDefaultTextStyle = typeName == 'DefaultTextStyle';
    final isAnimatedTextStyle = typeName == 'AnimatedDefaultTextStyle';
    if (!isDefaultTextStyle && !isAnimatedTextStyle) {
      return;
    }
    // `DefaultTextStyle.merge` keeps the inherited style, so it is allowed.
    if (isDefaultTextStyle && node.constructorName.name?.name == 'merge') {
      return;
    }
    final styleExpression = _styleArgument(node);
    if (styleExpression is! InstanceCreationExpression) {
      return;
    }
    final styleElement = styleExpression.constructorName.type.element;
    if (styleElement is InterfaceElement && styleElement.name == 'TextStyle') {
      rule.reportAtNode(node);
    }
  }

  /// Returns the expression passed to the `style` named argument, if any.
  Expression? _styleArgument(InstanceCreationExpression node) {
    for (final argument in node.argumentList.arguments) {
      if (argument is NamedExpression && argument.name.label.name == 'style') {
        return argument.expression;
      }
    }
    return null;
  }
}
