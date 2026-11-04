/// 单任务互斥锁，保证同一任务不会并发执行。
///
/// 仅用于内核内部判定「上一轮是否仍在执行」，不阻塞调用方。
class TaskLock {
  final Set<String> _runningKeys = <String>{};

  /// 指定任务是否正在执行。
  bool isRunning(String key) {
    return _runningKeys.contains(key);
  }

  /// 尝试占用任务锁，已占用时返回 false。
  bool tryAcquire(String key) {
    if (_runningKeys.contains(key)) {
      return false;
    }
    _runningKeys.add(key);
    return true;
  }

  /// 释放任务锁，未占用时忽略。
  void release(String key) {
    _runningKeys.remove(key);
  }

  /// 清理全部占用状态，用于调度器销毁。
  void clear() {
    _runningKeys.clear();
  }
}
