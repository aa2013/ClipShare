class HotkeySettings {
  ///Windows 接管 win + v
  final bool takeOverWinV;

  ///Windows 在正常退出程序/卸载时恢复 win + v
  final bool restoreWinVOnExit;

  ///历史弹窗快捷键
  final String historyWindowHotKeys;

  ///文件发送弹窗快捷键
  final String syncFileHotKeys;

  ///显示主总体快捷键
  final String showMainWindows;

  ///退出app快捷键
  final String exitAppHotKeys;

  const HotkeySettings({
    this.takeOverWinV = false,
    this.restoreWinVOnExit = true,
    this.historyWindowHotKeys = '',
    this.syncFileHotKeys = '',
    this.showMainWindows = '',
    this.exitAppHotKeys = '',
  });
}
