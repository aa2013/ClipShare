import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../lib/src/dependency_direction_rule.dart';

/// 在临时包目录中写入文件。
void _writeFile(Directory dir, String relPath, String content) {
  final file = File(_normalizeJoin(dir, relPath));
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(content);
}

/// 拼接路径并统一分隔符为当前平台风格（analyzer 要求绝对且规范化路径）。
String _normalizeJoin(Directory dir, String relPath) =>
    p.normalize(p.join(dir.path, relPath));

/// 返回 [relPath] 文件经分析引擎报告的全部诊断名。
Future<List<String>> _diagnosticNames(
  AnalysisContextCollection collection,
  Directory dir,
  String relPath,
) async {
  final fullPath = _normalizeJoin(dir, relPath);
  final context = collection.contextFor(fullPath);
  final result = await context.currentSession.getErrors(fullPath);
  return (result as ErrorsResult).diagnostics
      .map((d) => d.errorCode.name)
      .toList();
}

/// 使用真实分析引擎验证依赖方向规则的集成测试。
///
/// 通过向 [Registry.ruleRegistry] 注册规则，并借助临时包目录，
/// 让分析引擎实际运行规则，断言各依赖方向场景的报告结果。
void main() {
  late Directory tempDir;
  late AnalysisContextCollection collection;

  setUpAll(() {
    Registry.ruleRegistry.registerWarningRule(DependencyDirectionRule());
  });

  tearDownAll(() {
    Registry.ruleRegistry.unregisterWarningRule(DependencyDirectionRule());
  });

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('dep_direction_test');
    _writeFile(tempDir, 'pubspec.yaml', 'name: dep_direction_test_pkg\n');
    // 需包含 linter 段，否则分析引擎不会加载 warning rule。
    _writeFile(tempDir, 'analysis_options.yaml', 'linter:\n  rules:\n');
    _writeFile(
      tempDir,
      'lib/shared/shared.dart',
      'class SharedClass {}\n',
    );
    _writeFile(
      tempDir,
      'lib/core/core.dart',
      "import '../shared/shared.dart';\nclass CoreClass {}\n",
    );
    _writeFile(
      tempDir,
      'lib/core/bad_core.dart',
      "import '../features/feature.dart';\nclass BadCoreClass {}\n",
    );
    _writeFile(
      tempDir,
      'lib/features/feature.dart',
      "import '../core/core.dart';\nimport '../shared/shared.dart';\n"
      'class FeatureClass {}\n',
    );
    _writeFile(
      tempDir,
      'lib/shared/bad_shared.dart',
      "import '../core/core.dart';\nclass BadSharedClass {}\n",
    );
    _writeFile(
      tempDir,
      'lib/features/other_feature.dart',
      "import '../features/feature.dart';\nclass OtherFeatureClass {}\n",
    );
    _writeFile(
      tempDir,
      'lib/main.dart',
      "import 'core/core.dart';\nimport 'features/feature.dart';\n"
      'void main() {}\n',
    );
    collection = AnalysisContextCollection(includedPaths: [tempDir.path]);
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  test('core 依赖 shared（合法，不报告）', () async {
    final names =
        await _diagnosticNames(collection, tempDir, 'lib/core/core.dart');
    expect(names, isNot(contains('dependency_direction')));
  });

  test('core 依赖 features（反向依赖，报告）', () async {
    final names =
        await _diagnosticNames(collection, tempDir, 'lib/core/bad_core.dart');
    expect(names, contains('dependency_direction'));
  });

  test('features 依赖 core 与 shared（合法，不报告）', () async {
    final names =
        await _diagnosticNames(collection, tempDir, 'lib/features/feature.dart');
    expect(names, isNot(contains('dependency_direction')));
  });

  test('shared 依赖 core（反向依赖，报告）', () async {
    final names = await _diagnosticNames(
      collection,
      tempDir,
      'lib/shared/bad_shared.dart',
    );
    expect(names, contains('dependency_direction'));
  });

  test('features 依赖 features（同层，合法，不报告）', () async {
    final names = await _diagnosticNames(
      collection,
      tempDir,
      'lib/features/other_feature.dart',
    );
    expect(names, isNot(contains('dependency_direction')));
  });

  test('lib 根目录文件（组装层）豁免，不报告', () async {
    final names =
        await _diagnosticNames(collection, tempDir, 'lib/main.dart');
    expect(names, isNot(contains('dependency_direction')));
  });
}
