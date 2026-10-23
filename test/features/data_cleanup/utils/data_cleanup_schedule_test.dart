import 'package:clipshare/core/settings/data_cleanup/data_cleanup_freq.dart';
import 'package:clipshare/features/data_cleanup/enums/week_day.dart';
import 'package:clipshare/features/data_cleanup/utils/data_cleanup_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildCronExpression', () {
    test('builds daily cron from minute and hour', () {
      final cron = buildCronExpression(
        frequency: DataCleanupFreq.day,
        minute: '30',
        hour: '08',
        cronInput: '',
      );

      expect(cron, '30 08 * * *');
    });

    test('builds weekly cron and defaults to monday when week day is null', () {
      final cron = buildCronExpression(
        frequency: DataCleanupFreq.week,
        minute: '30',
        hour: '08',
        cronInput: '',
      );

      expect(cron, '30 08 * * 1');
    });

    test('builds weekly cron with selected week day value', () {
      final cron = buildCronExpression(
        frequency: DataCleanupFreq.week,
        minute: '00',
        hour: '12',
        weekDay: WeekDay.sunday,
        cronInput: '',
      );

      expect(cron, '00 12 * * 0');
    });

    test('returns trimmed user input in cron mode', () {
      final cron = buildCronExpression(
        frequency: DataCleanupFreq.cron,
        minute: '30',
        hour: '08',
        cronInput: '  0 0 * * *  ',
      );

      expect(cron, '0 0 * * *');
    });
  });

  group('nextExecTimeOf', () {
    test('returns next time for valid cron', () {
      final now = DateTime.now();
      final next = nextExecTimeOf('0 12 * * *');

      expect(next, isNotNull);
      expect(next!.hour, 12);
      expect(next.isAfter(now), isTrue);
    });

    test('returns null for invalid cron', () {
      final next = nextExecTimeOf('not a cron');

      expect(next, isNull);
    });
  });
}
