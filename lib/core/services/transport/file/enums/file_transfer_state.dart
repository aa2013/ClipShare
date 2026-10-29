/// 单文件传输任务状态
enum FileTransferState {
  /// 排队等待发送
  pending,

  /// 传输中
  transferring,

  /// 传输完成
  done,

  /// 已被用户终止
  canceled,

  /// 传输失败
  error,
}
