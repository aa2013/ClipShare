import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../lib/src/default_text_style_font_rule.dart';

/// 返回 [filePath] 文件经分析引擎报告的全部诊断名。
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

/// 使用真实分析引擎验证裸 TextStyle 规则的集成测试。
///
/// 规则依赖 Flutter 类型解析，因此在主项目 `lib` 下写入临时文件后分析并清理。
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
    // 测试工作目录为插件根（tools/clipshare_dependency_lint），主项目在其上两级。
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
