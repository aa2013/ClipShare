import 'package:clipshare/shared/utils/log.dart';

enum DataCleanupFreq {
  day,
  week,
  cron,
  unknown;

  static DataCleanupFreq parse(String value) {
    return DataCleanupFreq.values.firstWhere(
      (e) => e.name.toUpperCase() == value.toUpperCase(),
      orElse: () {
        logger.debug('DataCleanupFreq', "key '$value' unknown");
        return DataCleanupFreq.unknown;
      },
    );
  }
}
