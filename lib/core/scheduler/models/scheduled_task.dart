import 'package:clipshare/core/scheduler/schedule/schedule.dart';
import 'package:clipshare/core/scheduler/task_handler.dart';

/// 定时任务
class ScheduledTask {
  /// 任务唯一标识，重复注册时按 key 覆盖
  final String key;

  /// 调度策略，支持固定周期与 cron
  final Schedule schedule;

  /// 任务执行体
  final TaskHandler handler;

  /// 单次执行超时时间，null 表示不限制
  final Duration? timeout;

  /// 启动或恢复时发现错过计划点是否补跑一次
  final bool runOnMissed;

  /// 注册后是否立即异步执行一次
  final bool runImmediately;

  /// 上一轮仍在执行时是否跳过本轮，false 表示等上一轮完成后继续排队执行
  final bool skipIfRunning;

  const ScheduledTask({
    required this.key,
    required this.schedule,
    required this.handler,
    this.timeout,
    this.runOnMissed = true,
    this.runImmediately = false,
    this.skipIfRunning = true,
  });

  @override
  String toString() {
    return 'ScheduledTask(key: $key, schedule: $schedule)';
  }
}
