import 'package:clipshare/core/utils/log.dart';

enum CleanDataFreq {
  day,
  week,
  cron,
  unknown;

  static CleanDataFreq parse(String value) {
    return CleanDataFreq.values.firstWhere(
      (e) => e.name.toUpperCase() == value.toUpperCase(),
      orElse: () {
        logger.debug('CleanDataFreq', "key '$value' unknown");
        return CleanDataFreq.unknown;
      },
    );
  }
}
