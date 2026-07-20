import 'dart:async';

import 'package:clipshare/app/utils/parallerl_task.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ParallelTask', () {
    test('never exceeds the configured concurrency', () async {
      var running = 0;
      var maxRunning = 0;
      final tasks = List<FutureFunction>.generate(12, (_) {
        return () async {
          running++;
          if (running > maxRunning) maxRunning = running;
          await Future<void>.delayed(const Duration(milliseconds: 10));
          running--;
        };
      });

      await ParallelTask(tasks: tasks, maxParallelCnt: 3).run();

      expect(maxRunning, 3);
      expect(running, 0);
    });

    test('isolates task errors and continues remaining work', () async {
      final completed = <int>[];
      final task = ParallelTask(
        maxParallelCnt: 1,
        tasks: <FutureFunction>[
          () async => completed.add(1),
          () async => throw StateError('expected test failure'),
          () async => completed.add(3),
        ],
      );

      await task.run();

      expect(completed, <int>[1, 3]);
      expect(task.isCompleted, isTrue);
    });

    test('stop prevents new tasks and waits for started tasks', () async {
      final gate = Completer<void>();
      final firstWorkersStarted = Completer<void>();
      var started = 0;
      final tasks = List<FutureFunction>.generate(6, (_) {
        return () async {
          started++;
          if (started == 2) firstWorkersStarted.complete();
          await gate.future;
        };
      });
      final task = ParallelTask(tasks: tasks, maxParallelCnt: 2);
      final runFuture = task.run();
      await firstWorkersStarted.future;

      final stopFuture = task.stop();
      expect(task.isCompleted, isFalse);
      gate.complete();
      await stopFuture;
      await runFuture;

      expect(started, 2);
      expect(task.isCompleted, isTrue);
    });

    test('a canceled token starts no tasks', () async {
      final tokenSource = CancelTokenSource()..cancel();
      var started = false;

      await ParallelTask(
        tasks: <FutureFunction>[() async => started = true],
        token: tokenSource.token,
      ).run();

      expect(started, isFalse);
    });
  });
}
