import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../lib/src/default_text_style_font_rule.dart';

/// Returns all diagnostic names reported by the analysis engine for [filePath].
Future<List<String>> _diagnosticNames(
  AnalysisContextCollection collection,
  String filePath,
) async {
  final context = collection.contextFor(filePath);
  final result = await context.currentSession.getErrors(filePath);
  return (result as ErrorsResult).diagnostics
      .map((d) => d.diagnosticCode.name)
      .toList();
}

/// Integration test that validates the raw TextStyle rule with the real
/// analysis engine.
///
/// The rule relies on Flutter type resolution, so a temporary file is written
/// under the main project's `lib`, analyzed, and then cleaned up.
void main() {
  late Directory projectRoot;
  late Directory tempDir;
  late AnalysisContextCollection collection;

  setUpAll(() {
    Registry.ruleRegistry.registerWarningRule(DefaultTextStyleFontRule());
  });

  tearDownAll(() {
    Registry.ruleRegistry.unregisterWarningRule(DefaultTextStyleFontRule());
  });

  setUp(() {
    // The working directory is the plugin root (tools/clipshare_dependency_lint),
    // and the main project is two levels above.
    projectRoot = Directory(p.normalize(p.join(Directory.current.path, '..', '..')));
    tempDir = Directory(p.join(projectRoot.path, 'lib', 'tmp_default_text_style_lint'))
      ..createSync(recursive: true);
    collection = AnalysisContextCollection(includedPaths: [tempDir.path]);
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('裸 TextStyle 用于 DefaultTextStyle / AnimatedDefaultTextStyle 会被报告', () async {
    final file = File(p.join(tempDir.path, 'bad.dart'));
    file.writeAsStringSync('''
import 'package:flutter/material.dart';

Widget badDefault() =>
    DefaultTextStyle(style: TextStyle(color: Colors.red), child: const Text('x'));

Widget badAnimated(BuildContext context) => AnimatedDefaultTextStyle(
      style: TextStyle(color: Colors.red),
      duration: Duration.zero,
      child: const Text('x'),
    );
''');
    final names = await _diagnosticNames(collection, file.path);
    expect(names, contains('default_text_style_font'));
  });

  test('DefaultTextStyle.merge 与派生样式不会被报告', () async {
    final file = File(p.join(tempDir.path, 'ok.dart'));
    file.writeAsStringSync('''
import 'package:flutter/material.dart';

Widget okMerge() =>
    DefaultTextStyle.merge(style: TextStyle(color: Colors.red), child: const Text('x'));

Widget okAnimated(BuildContext context) => AnimatedDefaultTextStyle(
      style: DefaultTextStyle.of(context).style.copyWith(color: Colors.red),
      duration: Duration.zero,
      child: const Text('x'),
    );
''');
    final names = await _diagnosticNames(collection, file.path);
    expect(names, isNot(contains('default_text_style_font')));
  });
}
