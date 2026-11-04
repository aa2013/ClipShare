import 'package:clipshare/core/scheduler/schedule/schedule.dart';

/// 固定周期调度策略
class IntervalSchedule extends Schedule {
  /// 执行周期，必须为正值，否则不具备可调度语义。
  final Duration interval;

  const IntervalSchedule(this.interval);

  @override
  DateTime? nextRun(DateTime from) {
    if (interval <= Duration.zero) {
      return null;
    }
    return from.add(interval);
  }

  @override
  String toString() {
    return 'IntervalSchedule(interval: $interval)';
  }
}
