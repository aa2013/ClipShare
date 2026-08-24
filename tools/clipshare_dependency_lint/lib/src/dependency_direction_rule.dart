import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Maps layer names to their dependency level.
///
/// The allowed dependency direction is strictly increasing:
/// features -> core -> shared.
enum DependencyLayer {
  /// Lowest layer, depended on by any upper layer.
  shared,

  /// Core layer, may depend on shared, must not depend on features.
  core,

  /// Feature layer, may depend on core and shared.
  features,
}

/// Resolves the dependency layer of a file from its absolute filesystem path.
///
/// The path must contain a `lib/(shared|core|features)/` segment; files in the
/// lib root (assembly layer) and unmatched files return null.
DependencyLayer? layerOfFile(String path) {
  final normalized = path.replaceAll('\\', '/');
  final match =
      RegExp(r'/lib/(shared|core|features)/').firstMatch(normalized);
  if (match == null) {
    return null;
  }
  return _layerOfSegment(match.group(1)!);
}

/// Resolves the dependency layer of a target file from a `package:clipshare/...`
/// URI.
///
/// Returns null when the target is outside the three lib layers
/// (for example, a file in the lib root).
DependencyLayer? layerOfPackageUri(String uri) {
  const prefix = 'package:clipshare/';
  if (!uri.startsWith(prefix)) {
    return null;
  }
  return _layerOfSegment(uri.substring(prefix.length).split('/').first);
}

/// Maps a directory segment name (shared/core/features) to a dependency layer.
DependencyLayer? _layerOfSegment(String segment) {
  return switch (segment) {
    'shared' => DependencyLayer.shared,
    'core' => DependencyLayer.core,
    'features' => DependencyLayer.features,
    _ => null,
  };
}

/// Rule that validates whether import/export respects the layered dependency
/// direction.
class DependencyDirectionRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'dependency_direction',
    'Reverse dependency: only features -> core -> shared is allowed.',
    correctionMessage:
        'Adjust the import target so the direction follows features -> core -> shared.',
    severity: DiagnosticSeverity.ERROR,
  );

  DependencyDirectionRule()
    : super(
        name: 'dependency_direction',
        description:
            'Validates clipshare layered dependency direction, rejecting reverse dependencies.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this, context);
    registry.addImportDirective(this, visitor);
    registry.addExportDirective(this, visitor);
  }
}

/// Visitor that walks import/export directives and reports reverse dependencies.
class _Visitor extends SimpleAstVisitor<void> {
  final DependencyDirectionRule rule;

  final RuleContext context;

  _Visitor(this.rule, this.context);

  @override
  void visitImportDirective(ImportDirective node) {
    _check(node, node.uri.stringValue);
  }

  @override
  void visitExportDirective(ExportDirective node) {
    _check(node, node.uri.stringValue);
  }

  /// Checks a single directive: a dependency is illegal when the source layer
  /// is higher than the target layer.
  void _check(Directive node, String? rawUri) {
    if (rawUri == null) {
      return;
    }
    final currentUnit = context.currentUnit;
    if (currentUnit == null) {
      return;
    }
    // Files outside the three lib layers (for example, assembly files in the
    // lib root) are exempt from the check.
    final sourceLayer = layerOfFile(currentUnit.file.path);
    if (sourceLayer == null) {
      return;
    }
    // Resolve the dependency layer of the target URI.
    DependencyLayer? targetLayer;
    if (rawUri.startsWith('package:clipshare/')) {
      targetLayer = layerOfPackageUri(rawUri);
    } else if (rawUri.startsWith('../') || rawUri.startsWith('./')) {
      // Relative import: resolve the target to an absolute path based on the
      // current file location before determining its layer.
      final currentUri = Uri.file(currentUnit.file.path.replaceAll('\\', '/'));
      final resolved = currentUri.resolveUri(Uri.parse(rawUri));
      targetLayer = layerOfFile(resolved.toFilePath());
    }
    if (targetLayer == null) {
      return;
    }
    // The dependency direction is strictly increasing: the target layer must
    // not be higher than the source layer. A larger target index (for example,
    // core -> features or shared -> core) is a reverse dependency.
    if (sourceLayer.index < targetLayer.index) {
      rule.reportAtNode(node);
    }
  }
}
