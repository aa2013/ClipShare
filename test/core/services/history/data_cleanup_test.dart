import 'package:clipshare/core/services/history/data_cleanup_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DataCleanupNotifier.resolveCleanTimeRange', () {
    test('keeps given dates when days filter is disabled', () {
      final range = DataCleanupNotifier.resolveCleanTimeRange(
        useDaysFilter: false,
        saveDays: 30,
        startDate: '2026-01-01',
        endDate: '2026-02-01',
      );

      expect(range.start, '2026-01-01');
      expect(range.end, '2026-02-01');
    });

    test('keeps null dates when days filter is disabled and dates are empty', () {
      final range = DataCleanupNotifier.resolveCleanTimeRange(
        useDaysFilter: false,
        saveDays: 30,
      );

      expect(range.start, isNull);
      expect(range.end, isNull);
    });

    test('resolves to epoch start and today minus save days when enabled', () {
      final now = DateTime(2026, 10, 24);
      final range = DataCleanupNotifier.resolveCleanTimeRange(
        useDaysFilter: true,
        saveDays: 30,
        startDate: '2026-01-01',
        endDate: '2026-02-01',
        now: now,
      );

      // 启用天数过滤时忽略传入的起止日期
      expect(range.start, '1970-01-01');
      expect(range.end, '2026-09-24');
    });

    test('end date equals today when save days is zero', () {
      final now = DateTime(2026, 10, 24);
      final range = DataCleanupNotifier.resolveCleanTimeRange(
        useDaysFilter: true,
        saveDays: 0,
        now: now,
      );

      expect(range.start, '1970-01-01');
      expect(range.end, '2026-10-24');
    });
  });
}
