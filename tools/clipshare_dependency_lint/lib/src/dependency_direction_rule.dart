import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// 分层名称与依赖层级映射。
///
/// 允许的依赖方向为层级单向递增：features -> core -> shared。
enum DependencyLayer {
  /// 最底层，可被任意上层依赖。
  shared,

  /// 核心层，可依赖 shared，禁止依赖 features。
  core,

  /// 功能层，可依赖 core 与 shared。
  features,
}

/// 从文件系统绝对路径中解析文件所属的依赖层。
///
/// 路径需包含 `lib/(shared|core|features)/` 分段，lib 根目录（组装层）
/// 及未匹配的文件返回 null。
DependencyLayer? layerOfFile(String path) {
  final normalized = path.replaceAll('\\', '/');
  final match =
      RegExp(r'/lib/(shared|core|features)/').firstMatch(normalized);
  if (match == null) {
    return null;
  }
  return _layerOfSegment(match.group(1)!);
}

/// 从 `package:clipshare/...` 形式的 URI 中解析目标文件所属的依赖层。
///
/// 目标不在 lib 三层内（如 lib 根目录文件）返回 null。
DependencyLayer? layerOfPackageUri(String uri) {
  const prefix = 'package:clipshare/';
  if (!uri.startsWith(prefix)) {
    return null;
  }
  return _layerOfSegment(uri.substring(prefix.length).split('/').first);
}

/// 将目录分段名（shared/core/features）映射为依赖层。
DependencyLayer? _layerOfSegment(String segment) {
  return switch (segment) {
    'shared' => DependencyLayer.shared,
    'core' => DependencyLayer.core,
    'features' => DependencyLayer.features,
    _ => null,
  };
}

/// 校验 import/export 是否符合分层依赖方向的 warning 规则。
class DependencyDirectionRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'dependency_direction',
    '反向依赖：仅允许 features -> core -> shared 的单向依赖。',
    correctionMessage: '调整 import 目标，使依赖方向符合 features -> core -> shared。',
    severity: DiagnosticSeverity.ERROR,
  );

  DependencyDirectionRule()
    : super(
        name: 'dependency_direction',
        description: '校验 clipshare 分层依赖方向，禁止反向依赖。',
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

/// 遍历 import/export 指令并报告反向依赖的 visitor。
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

  /// 校验单个指令：源文件层高于目标文件层即为反向依赖。
  void _check(Directive node, String? rawUri) {
    if (rawUri == null) {
      return;
    }
    final currentUnit = context.currentUnit;
    if (currentUnit == null) {
      return;
    }
    // 源文件不在 lib 三层内（如 lib 根目录的组装文件），豁免检查。
    final sourceLayer = layerOfFile(currentUnit.file.path);
    if (sourceLayer == null) {
      return;
    }
    // 解析目标 URI 所属依赖层。
    DependencyLayer? targetLayer;
    if (rawUri.startsWith('package:clipshare/')) {
      targetLayer = layerOfPackageUri(rawUri);
    } else if (rawUri.startsWith('../') || rawUri.startsWith('./')) {
      // 相对导入：基于当前文件位置解析目标绝对路径后再判定层级。
      final currentUri = Uri.file(currentUnit.file.path.replaceAll('\\', '/'));
      final resolved = currentUri.resolveUri(Uri.parse(rawUri));
      targetLayer = layerOfFile(resolved.toFilePath());
    }
    if (targetLayer == null) {
      return;
    }
    // 依赖方向单向递增：目标层层级不得高于源层。
    // 即目标 index 大于源 index（如 core -> features、shared -> core）为反向依赖。
    if (sourceLayer.index < targetLayer.index) {
      rule.reportAtNode(node);
    }
  }
}
