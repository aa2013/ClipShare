/// 桌面端自定义标题栏/窗体控制的运行时状态。
class WindowControlState {
  /// 当前是否最大化
  final bool maxWindow;

  /// 是否允许最大化
  final bool maximizable;

  /// 是否允许最小化
  final bool minimizable;

  /// 是否允许关闭
  final bool closeable;

  /// 是否允许调整大小
  final bool resizable;

  /// 是否置顶
  final bool alwaysOnTop;

  /// 历史弹窗是否固定（固定后失焦不自动关闭）。
  final bool historyPopupPinned;

  const WindowControlState({
    this.maxWindow = false,
    this.maximizable = false,
    this.minimizable = false,
    this.closeable = true,
    this.resizable = false,
    this.alwaysOnTop = false,
    this.historyPopupPinned = false,
  });

  WindowControlState copyWith({
    bool? maxWindow,
    bool? maximizable,
    bool? minimizable,
    bool? closeable,
    bool? resizable,
    bool? alwaysOnTop,
    bool? historyPopupPinned,
  }) {
    return WindowControlState(
      maxWindow: maxWindow ?? this.maxWindow,
      maximizable: maximizable ?? this.maximizable,
      minimizable: minimizable ?? this.minimizable,
      closeable: closeable ?? this.closeable,
      resizable: resizable ?? this.resizable,
      alwaysOnTop: alwaysOnTop ?? this.alwaysOnTop,
      historyPopupPinned: historyPopupPinned ?? this.historyPopupPinned,
    );
  }
}
