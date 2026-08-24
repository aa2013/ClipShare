import 'package:easy_cron/easy_cron.dart';

class CronUtil {
  static DateTime? getNextTime(String cron) {
    final parser = UnixCronParser();
    late CronSchedule schedule;
    try {
      schedule = parser.parse(cron);
    } catch (_) {
      return null;
    }
    final nextTime = schedule.next().time;
    return nextTime;
  }
}
