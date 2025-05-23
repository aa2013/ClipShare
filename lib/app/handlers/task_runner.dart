import 'dart:async';
import 'dart:collection';

import 'package:clipshare/app/utils/log.dart';

/// copy from localsend
typedef FutureFunction<T> = Future<T> Function();

class TaskRunner<T> {
  static final tag = "TaskRunner";
  final StreamController<T> _streamController = StreamController();
  final Queue<FutureFunction<T>> _queue;

  final int concurrency;
  int _runnerCount = 0;
  bool _stopped = false;

  /// If [true], then the stream will be closed as soon as every task has been finished.
  /// By default, it is [false] when [initialTasks] is provided with a non-empty list.
  final bool _stayAlive;

  final void Function()? onFinish;

  TaskRunner({
    required this.concurrency,
    List<FutureFunction<T>>? initialTasks,
    bool? stayAlive,
    this.onFinish,
  })  : _queue = Queue()..addAll(initialTasks ?? []),
        _stayAlive = stayAlive ?? initialTasks == null || initialTasks.isEmpty {
    _fireRunners();
  }

  void addAll(Iterable<FutureFunction<T>> iterable) {
    _queue.addAll(iterable);
    _fireRunners();
  }

  void stop() {
    _stopped = true;
    _streamController.close();
  }

  Stream<T> get stream => _streamController.stream;

  /// Starts multiple runners until [concurrency].
  void _fireRunners() {
    if (_queue.isEmpty) {
      onFinish?.call();
    }
    while (_queue.isNotEmpty &&
        _runnerCount < concurrency &&
        !_streamController.isClosed) {
      _runnerCount++;
      unawaited(
        _runner(
          onFinish: () {
            _runnerCount--;
            if (_stopped || (_runnerCount == 0 && !_stayAlive)) {
              _streamController.close();
              if (!_stopped) {
                onFinish?.call();
              }
            }
          },
        ),
      );
    }
  }

  /// Processes the queue one by one.
  Future<void> _runner({required void Function() onFinish}) async {
    while (_queue.isNotEmpty) {
      final task = _queue.removeFirst();
      try {
        var res = await task();
        if (_streamController.isClosed || _stopped) {
          return;
        }
        _streamController.add(res);
      } catch (e) {
        Log.debug(tag, e.toString());
      }
    }
    onFinish();
  }
}
