import 'dart:io';

import 'package:clipshare/shared/extensions/number_extension.dart';
import 'package:clipshare/shared/extensions/time_extension.dart';
import 'package:logger/logger.dart';

class Log {
  Log._private();

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
