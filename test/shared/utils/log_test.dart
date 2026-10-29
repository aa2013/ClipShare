import 'dart:io';

import 'package:clipshare/shared/utils/log.dart';
import 'package:flutter_test/flutter_test.dart';

/// 日志清理测试：以文件名中的日期为归属判断依据，覆盖带后缀名称、无日期文件与保留窗口边界。
void main() {
  late Directory tempDir;

  /// 按当前系统日期推算 [daysAgo] 天前的日期字符串，保证断言与运行日期无关。
  String dateOf(int daysAgo) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return today.subtract(Duration(days: daysAgo)).toString().substring(0, 10);
  }

  /// 在临时日志目录中创建一个空日志文件并返回文件句柄。
  File createLog(String fileName) {
    final file = File('${tempDir.path}/$fileName');
    file.writeAsStringSync('');
    return file;
  }

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('clipshare_log_test_');
    logger.updateLogsDir(tempDir);
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('Log.cleanupLogs 保留窗口', () {
    test('删除早于保留窗口的文件，保留窗口内的文件', () async {
      final expired = createLog('${dateOf(Log.defaultRetainDays)}.txt');
      final newestExpired = createLog('${dateOf(Log.defaultRetainDays + 1)}.txt');
      final retainedToday = createLog('${dateOf(0)}.txt');
      final retainedBeforeToday = createLog('${dateOf(Log.defaultRetainDays - 1)}.txt');

      await logger.cleanupLogs();

      expect(expired.existsSync(), isFalse);
      expect(newestExpired.existsSync(), isFalse);
      expect(retainedToday.existsSync(), isTrue);
      expect(retainedBeforeToday.existsSync(), isTrue);
    });

    test('文件名带额外后缀时同样按日期识别', () async {
      final expired = createLog('${dateOf(5)}-Android.txt');
      final retained = createLog('${dateOf(0)}-Android.txt');

      await logger.cleanupLogs();

      expect(expired.existsSync(), isFalse);
      expect(retained.existsSync(), isTrue);
    });

    test('名称中无日期的文件不参与清理', () async {
      final withoutDate = createLog('notes.txt');
      final malformedDate = createLog('9999-99-99-error.log');

      await logger.cleanupLogs();

      expect(withoutDate.existsSync(), isTrue);
      expect(malformedDate.existsSync(), isTrue);
    });

    test('保留天数可覆盖，仅保留当天日志', () async {
      final yesterday = createLog('${dateOf(1)}.txt');
      final today = createLog('${dateOf(0)}.txt');

      await logger.cleanupLogs(retainDays: 1);

      expect(yesterday.existsSync(), isFalse);
      expect(today.existsSync(), isTrue);
    });

    test('日志目录不存在时不抛异常', () async {
      tempDir.deleteSync(recursive: true);

      await logger.cleanupLogs();
    });
  });
}
