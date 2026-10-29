/// 屏幕状态事件
sealed class ScreenEvent {
  const ScreenEvent();
}

/// 屏幕开启事件
class ScreenOpenedEvent extends ScreenEvent {
  const ScreenOpenedEvent();
}

/// 屏幕解锁事件
class ScreenUnlockedEvent extends ScreenEvent {
  const ScreenUnlockedEvent();
}

/// 屏幕关闭事件
class ScreenClosedEvent extends ScreenEvent {
  const ScreenClosedEvent();
}
