import 'package:clipshare/core/scheduler/enums/task_run_status.dart';

/// 单次任务执行结果。
class TaskResult {
  /// 任务唯一标识
  final String key;

  /// 执行状态
  final TaskRunStatus status;

  /// 执行耗时
  final Duration elapsed;

  /// 失败时的错误信息，成功或跳过时为 null
  final String? error;

  const TaskResult({
    required this.key,
    required this.status,
    required this.elapsed,
    this.error,
  });

  bool get isSuccess => status == TaskRunStatus.success;

  /// 构造成功结果。
  factory TaskResult.success(String key, Duration elapsed) {
    return TaskResult(key: key, status: TaskRunStatus.success, elapsed: elapsed);
  }

  /// 构造失败结果，[error] 为异常概要信息。
  factory TaskResult.failed(String key, Duration elapsed, String error) {
    return TaskResult(key: key, status: TaskRunStatus.failed, elapsed: elapsed, error: error);
  }

  /// 构造跳过结果，[reason] 说明跳过原因。
  factory TaskResult.skipped(String key, String reason) {
    return TaskResult(key: key, status: TaskRunStatus.skipped, elapsed: Duration.zero, error: reason);
  }

  @override
  String toString() {
    return 'TaskResult(key: $key, status: ${status.name}, elapsed: ${elapsed.inMilliseconds}ms, error: $error)';
  }
}
