import 'dart:convert';
import 'dart:io';

/// 依赖方向检查脚本：直接连接 analysis server 并等待插件 isolate 完成，
/// 可靠报告反向依赖违规（shared -> core -> features）。
///
/// 背景：`flutter analyze` 与 `dart analyze <目录>` 在分析大项目时不会等待
/// analysis_server_plugin 插件 isolate 完成分析，插件诊断（dependency_direction）
/// 可能被丢弃。本脚本等插件分析结束，结果可靠，适合命令行与 CI 使用。
///
/// 用法：
///   dart run scripts/check_dependency_direction.dart [项目根目录]
///
/// 退出码：
///   0 无违规；1 存在违规；2 执行失败或超时。

/// 等待分析空闲的时间（秒）：超过该时长未收到新的分析结果视为完成。
const _idleTimeoutSeconds = 12;

/// 分析总超时（秒），防止插件异常导致脚本挂死。
const _overallTimeoutSeconds = 180;

/// 依赖方向诊断的代码名，与插件中的 LintCode 保持一致。
const _dependencyCode = 'dependency_direction';

Future<void> main(List<String> args) async {
  final projectRoot = args.isNotEmpty
      ? Directory(args.first).absolute.path
      : Directory.current.absolute.path;

  // 由 dart 解释器路径推导 dart sdk 根目录（形如 .../dart-sdk）。
  final sdkPath = File(Platform.resolvedExecutable).parent.parent.path;
  final sep = Platform.pathSeparator;
  final snapshot = '$sdkPath${sep}bin${sep}snapshots${sep}analysis_server.dart.snapshot';

  late Process server;
  try {
    server = await Process.start(
      '$sdkPath${sep}bin${sep}dart',
      [snapshot, '--sdk', sdkPath, '--suppress-analytics'],
    );
  } on Exception catch (e) {
    stderr.writeln('启动 analysis server 失败：$e');
    exitCode = 2;
    return;
  }

  var id = 0;
  final violations = <String>{};
  var lastActivity = DateTime.now();
  var mainAnalysisDone = false;

  void handleLine(String line) {
    if (!line.startsWith('{')) return;
    try {
      final obj = jsonDecode(line) as Map;
      switch (obj['event']) {
        case 'analysis.errors':
          lastActivity = DateTime.now();
          final errors = (obj['params'] as Map)['errors'] as List;
          for (final e in errors) {
            if ((e as Map)['code'] == _dependencyCode) {
              violations.add((obj['params'] as Map)['file'] as String);
            }
          }
        case 'server.status':
          final analysis = (obj['params'] as Map)['analysis'];
          if (analysis != null && analysis['isAnalyzing'] == false) {
            mainAnalysisDone = true;
          }
      }
    } catch (_) {
      // 忽略无法解析的协议消息。
    }
  }

  server.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen(handleLine);

  void send(String method, [Map? params]) {
    server.stdin.writeln(jsonEncode({
      'jsonrpc': '2.0',
      'id': '${id++}',
      'method': method,
      'params': params ?? {},
    }));
  }

  send('server.setSubscriptions', {'subscriptions': ['STATUS']});
  send('analysis.setAnalysisRoots', {
    'included': [projectRoot],
    'excluded': <String>[],
  });

  // 等待主进程分析完成且插件 isolate 进入空闲。
  final start = DateTime.now();
  while (true) {
    await Future.delayed(const Duration(seconds: 2));
    final isIdle = DateTime.now().difference(lastActivity).inSeconds >=
        _idleTimeoutSeconds;
    if (mainAnalysisDone && isIdle) break;
    final elapsed = DateTime.now().difference(start).inSeconds;
    if (elapsed > _overallTimeoutSeconds) {
      stderr.writeln('分析超时（${_overallTimeoutSeconds}s），插件可能未完成。');
      server.kill();
      exitCode = 2;
      return;
    }
  }
  server.kill();

  if (violations.isEmpty) {
    stdout.writeln('未发现反向依赖违规（仅允许 features -> core -> shared）。');
    exitCode = 0;
    return;
  }

  final sorted = violations.toList()..sort();
  stdout.writeln('发现 ${sorted.length} 个文件存在反向依赖违规：');
  for (final v in sorted) {
    stdout.writeln('  - $v');
  }
  exitCode = 1;
}
