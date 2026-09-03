class LogSettings {
  ///是否启用日志记录
  final bool enableLogsRecord;

  ///Android 自动上传崩溃日志
  final bool enableAutoUploadCrashLogs;

  const LogSettings({
    this.enableLogsRecord = false,
    this.enableAutoUploadCrashLogs = false,
  });
}
