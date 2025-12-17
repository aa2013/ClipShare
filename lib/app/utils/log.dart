import 'dart:convert';
import 'dart:io';

import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/utils/extensions/number_extension.dart';
import 'package:clipshare/app/utils/extensions/time_extension.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';

class Log {
  Log._private();

  static Future _writeFuture = Future.value();
  static final _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
    ),
  );

  static void debug(String tag, dynamic) {
    var log = "[$tag] ${DateTime.now().format()} | $dynamic";
    _logger.d(log);
    writeLog("[debug] | $log");
  }

  static void trace(String tag, dynamic) {
    var log = "[$tag] ${DateTime.now().format()} | $dynamic";
    _logger.t(log);
    writeLog("[trace] | $log");
  }

  static void info(String tag, dynamic) {
    var log = "[$tag] ${DateTime.now().format()} | $dynamic";
    _logger.i(log);
    writeLog("[info] | $log");
  }

  static void warn(String tag, dynamic) {
    var log = "[$tag] ${DateTime.now().format()} | $dynamic";
    _logger.w(log);
    writeLog("[warn] | $log");
  }

  static void fatal(String tag, dynamic) {
    var log = "[$tag] ${DateTime.now().format()} | $dynamic";
    _logger.w(log);
    writeLog("[fatal] | $log");
  }

  static void error(String tag, err, [StackTrace? stack]) {
    final stackStr = stack != null ? ", $stack" : "";
    var log = "[$tag] ${DateTime.now().format()} | $err $stackStr";
    _logger.e(log);
    writeLog("[error] | $log");
  }

  static Future<void> writeLog(String content) async {
    final appConfig = Get.find<ConfigService>();
    try {
      if (!appConfig.enableLogsRecord) {
        return;
      }
    } catch (e) {
      return;
    }
    final logDirPath = appConfig.logsDirPath;
    var dateStr = DateTime.now().toString().substring(0, 10);
    var filePath = "$logDirPath/$dateStr.txt";
    Directory(logDirPath).createSync(recursive: true);
    var file = File(filePath);
    _writeFuture = _writeFuture.then(
      (v) => file.writeAsString("$content\n", mode: FileMode.writeOnlyAppend),
    );
  }

  static Future<void> writeAndroidLogToday() async {
    if (!Platform.isAndroid) {
      return;
    }
    DateTime now = DateTime.now();
    String timeStr =
        "${now.month.toString().padLeft(2, '0')}-"
        "${now.day.toString().padLeft(2, '0')} 00:00:00.000";
    var result = await Process.start('logcat', ['-T', timeStr, '-v', 'long', 'top.coclyun.clipshare:V']);
    List<int> bytes = [];
    result.stdout.listen((data) {
      // print(utf8.decode(data));
      bytes.addAll(data);
    });

    await Future.delayed(5.s, result.kill);

    final appConfig = Get.find<ConfigService>();
    final logDirPath = appConfig.logsDirPath;
    var dateStr = DateTime.now().toString().substring(0, 10);
    var filePath = "$logDirPath/$dateStr-Android.txt";
    Directory(logDirPath).createSync(recursive: true);
    var file = File(filePath);
    file.writeAsBytes(bytes);
  }
}
