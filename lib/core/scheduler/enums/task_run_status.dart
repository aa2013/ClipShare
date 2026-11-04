/// 单次任务执行状态。
enum TaskRunStatus {
  /// 执行成功
  success,

  /// 执行抛出异常或超时
  failed,

  /// 上一轮仍在执行或缺少注册项而跳过本次执行
  skipped,
}
