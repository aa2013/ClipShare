import 'package:clipshare/core/settings/data_cleanup/data_cleanup_config.dart';
import 'package:clipshare/core/settings/data_cleanup/data_cleanup_freq.dart';
import 'package:clipshare/shared/enums/history_content_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DataCleanupConfig.tryParse', () {
    test('round trips through toString', () {
      const config = DataCleanupConfig(
        tags: ['work'],
        devIds: ['device-1'],
        contentTypes: [HistoryContentType.image, HistoryContentType.file],
        saveTopData: true,
        removeFiles: true,
        autoClean: true,
        autoCleanFreq: DataCleanupFreq.week,
        cron: '0 0 * * 1',
        saveDays: 30,
      );

      final parsed = DataCleanupConfig.tryParse(config.toString());

      expect(parsed, isNotNull);
      expect(parsed!.tags, ['work']);
      expect(parsed.devIds, ['device-1']);
      expect(parsed.contentTypes, [HistoryContentType.image, HistoryContentType.file]);
      expect(parsed.saveTopData, isTrue);
      expect(parsed.removeFiles, isTrue);
      expect(parsed.autoClean, isTrue);
      expect(parsed.autoCleanFreq, DataCleanupFreq.week);
      expect(parsed.cron, '0 0 * * 1');
      expect(parsed.saveDays, 30);
    });

    test('returns null for malformed json', () {
      expect(DataCleanupConfig.tryParse('not json'), isNull);
    });

    test('falls back to day freq when stored freq is invalid', () {
      const json =
          '{"tags":[],"devIds":[],"contentTypes":[],"saveTopData":true,"removeFiles":false,"autoClean":true,"autoCleanFreq":"unknown"}';

      final parsed = DataCleanupConfig.tryParse(json);

      expect(parsed, isNotNull);
      expect(parsed!.autoCleanFreq, DataCleanupFreq.day);
    });

    test('drops unknown content types', () {
      const json =
          '{"tags":[],"devIds":[],"contentTypes":["Image","Something"],"saveTopData":true,"removeFiles":false,"autoClean":false}';

      final parsed = DataCleanupConfig.tryParse(json);

      expect(parsed, isNotNull);
      expect(parsed!.contentTypes, [HistoryContentType.image]);
    });
  });
}
