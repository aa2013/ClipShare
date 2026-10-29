import 'package:clipshare/core/scheduler/schedule/interval_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IntervalSchedule.nextRun', () {
    test('按周期推进到下一个触发点', () {
      const schedule = IntervalSchedule(Duration(minutes: 10));
      final from = DateTime(2026, 1, 1, 8, 0);

      expect(schedule.nextRun(from), DateTime(2026, 1, 1, 8, 10));
    });

    test('跨越零点时保持连续推进', () {
      const schedule = IntervalSchedule(Duration(hours: 5));
      final from = DateTime(2026, 1, 1, 22, 0);

      expect(schedule.nextRun(from), DateTime(2026, 1, 2, 3, 0));
    });

    test('周期非正值时无法调度', () {
      expect(const IntervalSchedule(Duration.zero).nextRun(DateTime(2026, 1, 1)), isNull);
      expect(const IntervalSchedule(Duration(seconds: -1)).nextRun(DateTime(2026, 1, 1)), isNull);
    });
  });
}
