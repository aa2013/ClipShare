import 'dart:convert';
import 'dart:io';

import 'package:clipshare/core/extensions/file_extension.dart';
import 'package:clipshare/core/settings/app_paths/app_paths.dart';
import 'package:clipshare/core/settings/app_paths/app_paths_provider.dart';
import 'package:clipshare/shared/utils/file_util.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'log_provider.g.dart';

/// 日志文件列表控制器。
///
/// 文件来自应用配置的日志目录，列表按文件名倒序排列，保证最新的日志在最前。
@riverpod
class LogsNotifier extends _$LogsNotifier {
  /// 应用路径配置，日志目录由配置统一提供。
  Future<AppPaths> get _appPaths => ref.read(appPathsProvider.future);

  @override
  Future<List<File>> build() async {
    final appPaths = await ref.watch(appPathsProvider.future);
    return _loadLogFiles(appPaths.logsDirPath);
  }

  /// 重新扫描日志目录并更新列表。
  ///
  /// 供下拉刷新、Android 日志生成完成后调用，直接替换为最新结果，
  /// 避免刷新过程中列表被加载态覆盖。
  Future<void> refresh() async {
    final appPaths = await _appPaths;
    state = AsyncData(_loadLogFiles(appPaths.logsDirPath));
  }

  /// 删除日志目录下的全部文件并清空列表。
  Future<void> clear() async {
    final appPaths = await _appPaths;
    FileUtil.deleteDirectoryFiles(appPaths.logsDirPath);
    state = const AsyncData([]);
  }

  /// 读取日志目录下的普通文件并按文件名倒序排列。
  List<File> _loadLogFiles(String logsDirPath) {
    final directory = Directory(logsDirPath);
    if (!directory.existsSync()) {
      return const [];
    }
    final logs = directory.listSync(recursive: false).whereType<File>().toList();
    logs.sort((a, b) => b.fileName.compareTo(a.fileName));
    return logs;
  }
}

/// 读取指定路径的日志文件内容。
///
/// 使用 [Utf8Decoder.allowMalformed] 容错解码，避免日志中的异常字节导致详情页无法打开。
@riverpod
Future<String> logContent(Ref ref, String path) {
  final file = File(path);
  return file.openRead().transform(const Utf8Decoder(allowMalformed: true)).join();
}
