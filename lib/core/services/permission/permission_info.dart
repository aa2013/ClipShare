class PermissionInfo {
  ///Android 通知权限
  final bool hasNotifyPermission;

  ///Android 悬浮窗权限
  final bool hasFloatWindowPermission;

  ///Android 电池忽略
  final bool hasIgnoreBatteryPermission;

  ///Android 短信读取
  final bool hasSmsReadPermission;

  ///Android 无障碍
  final bool hasAccessibilityPermission;

  ///Android 通知记录
  final bool hasNotificationRecordPermission;

  ///IOS 相册
  final bool hasIOSPhotosPermission;

  ///Android 剪贴板（AppOps）
  final bool hasClipboardPermission;

  const PermissionInfo({
    this.hasNotifyPermission = false,
    this.hasFloatWindowPermission = false,
    this.hasIgnoreBatteryPermission = false,
    this.hasSmsReadPermission = false,
    this.hasAccessibilityPermission = false,
    this.hasNotificationRecordPermission = false,
    this.hasIOSPhotosPermission = false,
    this.hasClipboardPermission = false,
  });
}
