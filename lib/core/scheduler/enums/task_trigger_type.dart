/// 任务触发来源，用于日志与排查不同生命周期入口。
enum TaskTriggerType {
  /// 正常定时触发
  timer,

  /// 启动或恢复时发现错过计划点后的补跑
  missed,

  /// 注册后立即执行
  register,

  /// 调用方手动触发
  manual,
}
