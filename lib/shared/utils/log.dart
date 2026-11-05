import 'dart:io';

import 'package:clipshare/shared/extensions/number_extension.dart';
import 'package:clipshare/shared/extensions/time_extension.dart';
import 'package:logger/logger.dart';

class Log {
  Log._private();

  /// 日志文件默认保留天数，包含当天在内的最近 N 天
  static const defaultRetainDays = 3;

  /// 定时任务key
  static const schedulerKey = 'log_cleanup';

  /// 日志文件名中的日期片段，文件名可能附带其它内容（如 `2026-11-05-Android.txt`）
  static final _fileNameDatePattern = RegExp(r'(\d{4})-(\d{2})-(\d{2})');

  static Future _writeFuture = Future.value();
  static final _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
    ),
  );
  Directory _logsDir = Directory.systemTemp;
  bool _enable = false;

  void enable() {
    _enable = true;
  }

  void disable() {
    _enable = false;
  }

  bool updateLogsDir(Directory dir) {
    if (dir.absolute.path == _logsDir.absolute.path) {
      return true;
    }
    try {
      dir.createSync(recursive: true);
      _logsDir = dir;
      return true;
    } catch (err, stack) {
      error('log', err, stack);
      return false;
    }
  }

  void debug(String tag, dynamic) {
    var log = "${DateTime.now().format("HH:mm:ss")} | [$tag] | $dynamic";
    _logger.d(log);
    writeLog('[debug] | $log');
  }

  void info(String tag, dynamic) {
    var log = "${DateTime.now().format("HH:mm:ss")} | [$tag] | $dynamic";
    _logger.i(log);
    writeLog('[info] | $log');
  }

  void warn(String tag, dynamic) {
    var log = "${DateTime.now().format("HH:mm:ss")} | [$tag] | $dynamic";
    _logger.w(log);
    writeLog('[warn] | $log');
  }

  void error(String tag, err, [StackTrace? stack]) {
    final stackStr = stack != null ? ', $stack' : '';
    var log = "${DateTime.now().format("HH:mm:ss")} | [$tag] | $err $stackStr";
    _logger.e(log);
    writeLog('[error] | $log');
  }

  /// 清理早于保留窗口的历史日志，只保留包含当天在内的最近 [retainDays] 天。
  ///
  /// 归属日期统一从文件名提取，与文件的创建/修改时间无关；
  /// 名称中提取不到日期的文件不受本规则管理，保持不动。
  Future<void> cleanupLogs({int retainDays = defaultRetainDays}) async {
    // 先等在途写入落盘，避免与追加写交错
    await _writeFuture;
    final directory = _logsDir;
    if (!directory.existsSync()) {
      return;
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final firstRetainedDate = today.subtract(Duration(days: retainDays - 1));
    final taggedExpired = <({DateTime date, File file})>[];
    for (final entity in directory.listSync(recursive: false)) {
      if (entity is! File) {
        continue;
      }
      final date = _parseFileDate(entity.uri.pathSegments.last);
      if (date == null || !date.isBefore(firstRetainedDate)) {
        continue;
      }
      taggedExpired.add((date: date, file: entity));
    }
    taggedExpired.sort((a, b) => a.date.compareTo(b.date));
    var deleted = 0;
    for (final item in taggedExpired) {
      try {
        await item.file.delete();
        deleted++;
      } catch (err, stack) {
        error('Log', 'delete expired log file ${item.file.path} failed. $err', stack);
      }
    }
    info('Log', 'cleanup expired logs done. retainDays=$retainDays, deleted=$deleted');
  }

  /// 从日志文件名中提取第一个合法日期，无法提取时返回 null。
  DateTime? _parseFileDate(String fileName) {
    final match = _fileNameDatePattern.firstMatch(fileName);
    if (match == null) {
      return null;
    }
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final date = DateTime(year, month, day);
    // DateTime 会把越界的月日自动进位，回读比对以排除 2026-13-01 这类非法日期
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }
    return date;
  }

  Future<void> writeLog(String content) async {
    try {
      if (!_enable) {
        return;
      }
    } catch (e) {
      return;
    }
    final logDirPath = _logsDir.path;
    var dateStr = DateTime.now().toString().substring(0, 10);
    var filePath = '$logDirPath/$dateStr.txt';
    Directory(logDirPath).createSync(recursive: true);
    var file = File(filePath);
    _writeFuture = _writeFuture.then(
      (v) => file.writeAsString('$content\n', mode: FileMode.writeOnlyAppend),
    );
  }

  Future<void> writeAndroidLogToday() async {
    if (!Platform.isAndroid) {
      return;
    }
    DateTime now = DateTime.now();
    String timeStr =
        "${now.month.toString().padLeft(2, '0')}-"
        "${now.day.toString().padLeft(2, '0')} 00:00:00.000";
    var result = await Process.start('logcat', [
      '-T',
      timeStr,
      '-v',
      'long',
      'top.coclyun.clipshare:V',
    ]);
    List<int> bytes = [];
    result.stdout.listen((data) {
      // print(utf8.decode(data));
      bytes.addAll(data);
    });

    await Future.delayed(5.s, result.kill);

    final logDirPath = _logsDir.path;
    var dateStr = DateTime.now().toString().substring(0, 10);
    var filePath = '$logDirPath/$dateStr-Android.txt';
    Directory(logDirPath).createSync(recursive: true);
    var file = File(filePath);
    await file.writeAsBytes(bytes);
  }
}

final logger = Log._private();
