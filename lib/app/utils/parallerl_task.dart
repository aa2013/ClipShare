import 'dart:async';
import 'package:flutter/cupertino.dart';

typedef FutureFunction = Future Function();

///取消令牌源
class CancelTokenSource {
  final CancelToken token = CancelToken();
  void cancel() {
    if (token._isCanceled) {
      throw 'Token already canceled';
    }
    token._isCanceled = true;
  }
}

///取消令牌
class CancelToken {
  static final none = CancelToken();
  bool _isCanceled = false;

  bool get isCanceled => _isCanceled;
}

///并行任务工具
class ParallelTask {
  final List<FutureFunction> _tasks;
  final Completer<void> _completer = Completer<void>();
  late final CancelToken _token;
  bool _running = false;
  bool _stopped = false;

  //最大并行执行的任务数量
  final int maxParallelCnt;

  bool get isCompleted => _completer.isCompleted;

  ParallelTask({
    required List<FutureFunction> tasks,
    this.maxParallelCnt = 10,
    CancelToken? token,
  }) : _tasks = tasks,
       _token = token ?? CancelToken.none;

  Future<void> run() async {
    try {
      if (_running) {
        throw 'Task already running';
      }
      if (_completer.isCompleted) {
        throw 'Task already completed';
      }
      if(_token.isCanceled){
        throw 'Task already canceled';
      }
      _running = true;

      await _runTasks();

      await _completer.future;
    } catch (err, stack) {
      debugPrintStack(stackTrace: stack);
    }
  }

  Future<void> stop() async {
    _stopped = true;
    if (!_completer.isCompleted) {
      _completer.complete();
    }
  }

  Future<void> _runTasks() async {
    if (_tasks.isEmpty) {
      _completer.complete();
      return;
    }

    int runningCount = 0;
    int index = 0;
    int completedCount = 0;

    Future<void> schedule() async {
      if (_stopped) return;
      if (_token.isCanceled) {
        _completer.complete();
        return;
      }

      while (index < _tasks.length && !_token.isCanceled) {
        if (_token.isCanceled) {
          _completer.complete();
          return;
        }
        if(runningCount >= maxParallelCnt){
          await Future.delayed(const Duration(milliseconds: 100));
          continue;
        }
        final task = _tasks[index++];
        runningCount++;

        task()
            .then((_) {
              runningCount--;
              completedCount++;

              if (completedCount == _tasks.length) {
                if (!_completer.isCompleted) {
                  _completer.complete();
                }
                return;
              }

              // schedule();
            })
            .catchError((err, stack) {
              debugPrintStack(stackTrace: stack);
              runningCount--;
              completedCount++;

              if (completedCount == _tasks.length) {
                if (!_completer.isCompleted) {
                  _completer.complete();
                }
                return;
              }

              schedule();
            });
      }
    }

    await schedule();
  }
}
