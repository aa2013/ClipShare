class NotificationSettings {
  ///（Android）是否记录通知历史
  final bool enableRecordNotification;

  ///设备连接时通知
  final bool notifyOnDevConn;

  ///设备断开连接时通知
  final bool notifyOnDevDisconn;

  ///（Android）是否显示移动端通知
  final bool enableShowMobileNotification;

  ///接收文件后是否弹出通知
  final bool notifyOnReceivedFile;

  const NotificationSettings({
    this.enableRecordNotification = false,
    this.notifyOnDevConn = false,
    this.notifyOnDevDisconn = false,
    this.enableShowMobileNotification = false,
    this.notifyOnReceivedFile = false,
  });
}
