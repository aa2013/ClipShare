/// 调度策略抽象
abstract class Schedule {
  const Schedule();

  /// 计算严格晚于 [from] 的下一个计划触发点，无法计算时返回 null。
  ///
  /// 返回 null 表示表达式非法或已无后续触发点，应停止该任务的调度。
  DateTime? nextRun(DateTime from);
}
