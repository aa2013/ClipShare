import 'package:clipshare/core/scheduler/schedule/cron_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CronSchedule.nextRun', () {
    test('每日表达式返回下一次对应时刻', () {
      final schedule = CronSchedule('30 8 * * *');
      final from = DateTime(2026, 1, 1, 9, 0);

      final next = schedule.nextRun(from)!;

      expect(next, DateTime(2026, 1, 2, 8, 30));
    });

    test('当日尚未到点时返回当天时刻', () {
      final schedule = CronSchedule('30 8 * * *');
      final from = DateTime(2026, 1, 1, 7, 0);

      final next = schedule.nextRun(from)!;

      expect(next, DateTime(2026, 1, 1, 8, 30));
    });

    test('每周表达式只命中指定星期', () {
      // 2026-01-01 为周四
      final schedule = CronSchedule('0 12 * * 1');
      final from = DateTime(2026, 1, 1, 0, 0);

      final next = schedule.nextRun(from)!;

      expect(next, DateTime(2026, 1, 5, 12, 0));
      expect(next.weekday, DateTime.monday);
    });

    test('非法表达式返回 null', () {
      expect(CronSchedule('not a cron').nextRun(DateTime(2026, 1, 1)), isNull);
    });

    test('结果严格晚于基准时间', () {
      final schedule = CronSchedule('0 0 * * *');
      final from = DateTime(2026, 1, 1, 0, 0);

      final next = schedule.nextRun(from)!;

      expect(next.isAfter(from), isTrue);
    });
  });
}
