import 'package:clipshare/core/scheduler/schedule/schedule.dart';
import 'package:easy_cron/easy_cron.dart' as cron;

/// cron 表达式调度策略。
///
/// 仅支持 Unix 五段式表达式（分 时 日 月 周）
class CronSchedule extends Schedule {
  /// Unix cron 表达式。
  final String expression;

  CronSchedule(this.expression);

  @override
  DateTime? nextRun(DateTime from) {
    final parser = cron.UnixCronParser();
    final cron.CronSchedule schedule;
    try {
      schedule = parser.parse(expression);
    } catch (_) {
      return null;
    }
    // easy_cron 以传入时间为基准向后查找，秒字段清零避免同一分钟内重复命中。
    final base = DateTime(from.year, from.month, from.day, from.hour, from.minute, from.second);
    return schedule.next(base).time;
  }

  @override
  String toString() {
    return 'CronSchedule(expression: $expression)';
  }
}
