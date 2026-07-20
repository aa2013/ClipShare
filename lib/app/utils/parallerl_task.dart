import 'dart:async';

import 'package:flutter/foundation.dart';

typedef FutureFunction = Future Function();

/// 取消令牌源，用于通知尚未开始的任务停止调度。
class CancelTokenSource {
  final CancelToken token = CancelToken();

  /// 重复取消保持幂等，便于多个生命周期入口共同收口。
  void cancel() {
    token._isCanceled = true;
  }
}

/// 只读取消令牌，已开始的任务由任务自身自然结束。
class CancelToken {
  static final none = CancelToken();
  bool _isCanceled = false;

  bool get isCanceled => _isCanceled;
}

/// 使用固定数量 worker 执行任务，并隔离单个任务的异常。
class ParallelTask {
  final List<FutureFunction> _tasks;
  final Completer<void> _completer = Completer<void>();
  final CancelToken _token;
  final int maxParallelCnt;
  bool _running = false;
  bool _stopped = false;
  int _nextTaskIndex = 0;

  bool get isCompleted => _completer.isCompleted;

  ParallelTask({
    required List<FutureFunction> tasks,
    this.maxParallelCnt = 10,
    CancelToken? token,
  }) : assert(maxParallelCnt > 0),
       _tasks = tasks,
       _token = token ?? CancelToken.none;

  /// 启动 worker；单个任务失败不会中断其他任务。
  Future<void> run() async {
    if (_running || _completer.isCompleted) {
      return _completer.future;
    }
    _running = true;
    if (_tasks.isEmpty || _stopped || _token.isCanceled) {
      _complete();
      return _completer.future;
    }

    final workerCount = _tasks.length < maxParallelCnt ? _tasks.length : maxParallelCnt;
    try {
      await Future.wait(List<Future<void>>.generate(workerCount, (_) => _runWorker()));
    } finally {
      _complete();
    }
    return _completer.future;
  }

  /// 停止派发新任务；已经启动的任务仍会自然收口。
  Future<void> stop() async {
    _stopped = true;
    if (!_running) {
      _complete();
    }
    await _completer.future;
  }

  /// 单个 worker 顺序领取任务，领取动作在同步区间内完成。
  Future<void> _runWorker() async {
    while (!_stopped && !_token.isCanceled) {
      if (_nextTaskIndex >= _tasks.length) {
        return;
      }
      final task = _tasks[_nextTaskIndex++];
      try {
        await task();
      } catch (error, stackTrace) {
        debugPrint('ParallelTask task failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    }
  }

  /// 只完成一次运行 Future。
  void _complete() {
    if (!_completer.isCompleted) {
      _completer.complete();
    }
  }
}
