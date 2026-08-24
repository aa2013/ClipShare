import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../lib/src/dependency_direction_rule.dart';

/// Writes a file into the temporary package directory.
void _writeFile(Directory dir, String relPath, String content) {
  final file = File(_normalizeJoin(dir, relPath));
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(content);
}

/// Joins a path and normalizes separators for the current platform (the
/// analyzer requires absolute, normalized paths).
String _normalizeJoin(Directory dir, String relPath) =>
    p.normalize(p.join(dir.path, relPath));

/// Returns all diagnostic names reported by the analysis engine for [relPath].
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

/// Integration test that validates the dependency direction rule with the real
/// analysis engine.
///
/// The rule is registered with [Registry.ruleRegistry], and a temporary package
/// directory lets the analysis engine actually run it, asserting the reported
/// result for each dependency direction scenario.
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
    // A linter section is required, otherwise the analysis engine will not load
    // warning rules.
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
