import 'package:clipshare/shared/extensions/time_extension.dart';

/// 单个任务的调度状态。
///
/// 描述处理进度
class TaskState {
  /// 上次已处理的计划触发点；null 表示从未处理过
  final DateTime? lastScheduledAt;

  /// 上次实际执行时间
  final DateTime? lastRunAt;

  const TaskState({this.lastScheduledAt, this.lastRunAt});

  const TaskState.empty() : lastScheduledAt = null, lastRunAt = null;

  TaskState copyWith({
    DateTime? lastScheduledAt,
    DateTime? lastRunAt,
  }) {
    return TaskState(
      lastScheduledAt: lastScheduledAt ?? this.lastScheduledAt,
      lastRunAt: lastRunAt ?? this.lastRunAt,
    );
  }

  /// 解析单个任务状态，字段缺失或格式非法时返回空状态。
  factory TaskState.tryParse(Map<String, dynamic>? json) {
    if (json == null) {
      return const TaskState.empty();
    }
    return TaskState(
      lastScheduledAt: DateTime.tryParse(json['lastScheduledAt']?.toString() ?? ''),
      lastRunAt: DateTime.tryParse(json['lastRunAt']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lastScheduledAt': lastScheduledAt?.format(),
      'lastRunAt': lastRunAt?.format(),
    };
  }
}
