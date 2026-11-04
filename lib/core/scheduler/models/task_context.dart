import 'package:clipshare/core/scheduler/enums/task_trigger_type.dart';

/// 单次任务执行的上下文
class TaskContext {
  /// 任务唯一标识
  final String key;

  /// 本次执行触发来源
  final TaskTriggerType triggerType;

  /// 本次执行的计划触发点；注册即执行、手动执行时为 null
  final DateTime? scheduledAt;

  const TaskContext({
    required this.key,
    required this.triggerType,
    this.scheduledAt,
  });
}
