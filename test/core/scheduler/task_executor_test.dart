import 'dart:async';

import 'package:clipshare/core/scheduler/enums/task_run_status.dart';
import 'package:clipshare/core/scheduler/enums/task_trigger_type.dart';
import 'package:clipshare/core/scheduler/models/scheduled_task.dart';
import 'package:clipshare/core/scheduler/models/task_context.dart';
import 'package:clipshare/core/scheduler/schedule/interval_schedule.dart';
import 'package:clipshare/core/scheduler/task_executor.dart';
import 'package:clipshare/core/scheduler/task_handler.dart';
import 'package:clipshare/core/scheduler/task_lock.dart';
import 'package:flutter_test/flutter_test.dart';

/// 记录执行次数的测试任务
class _CountingHandler extends TaskHandler {
  final FutureOr<void> Function(TaskContext context)? onRun;

  int count = 0;

  _CountingHandler({this.onRun});

  @override
  Future<void> run(TaskContext context) async {
    count++;
    await onRun?.call(context);
  }
}

ScheduledTask _buildTask({
  required TaskHandler handler,
  Duration? timeout,
  bool skipIfRunning = true,
}) {
  return ScheduledTask(
    key: 'test-task',
    schedule: const IntervalSchedule(Duration(minutes: 1)),
    handler: handler,
    timeout: timeout,
    skipIfRunning: skipIfRunning,
  );
}

void main() {
  group('TaskExecutor.execute', () {
    test('成功执行返回 success 并传入上下文', () async {
      final handler = _CountingHandler();
      final executor = TaskExecutor();

      final result = await executor.execute(
        _buildTask(handler: handler),
        const TaskContext(key: 'test-task', triggerType: TaskTriggerType.timer),
      );

      expect(result.status, TaskRunStatus.success);
      expect(handler.count, 1);
    });

    test('任务抛出异常时返回 failed 且不向外抛出', () async {
      final handler = _CountingHandler(onRun: (_) => throw StateError('boom'));
      final executor = TaskExecutor();

      final result = await executor.execute(
        _buildTask(handler: handler),
        const TaskContext(key: 'test-task', triggerType: TaskTriggerType.timer),
      );

      expect(result.status, TaskRunStatus.failed);
      expect(result.error, contains('boom'));
    });

    test('超过超时时间返回 failed', () async {
      final handler = _CountingHandler(
        onRun: (_) => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      final executor = TaskExecutor();

      final result = await executor.execute(
        _buildTask(handler: handler, timeout: const Duration(milliseconds: 20)),
        const TaskContext(key: 'test-task', triggerType: TaskTriggerType.timer),
      );

      expect(result.status, TaskRunStatus.failed);
      expect(result.error, contains('exceeded'));
    });

    test('上一轮未结束时按配置跳过本轮', () async {
      final completer = Completer<void>();
      final handler = _CountingHandler(onRun: (_) => completer.future);
      final executor = TaskExecutor();
      final task = _buildTask(handler: handler);
      const context = TaskContext(key: 'test-task', triggerType: TaskTriggerType.timer);

      final first = executor.execute(task, context);
      final second = await executor.execute(task, context);

      expect(second.status, TaskRunStatus.skipped);
      expect(handler.count, 1);

      completer.complete();
      expect((await first).status, TaskRunStatus.success);
    });

    test('执行结束后释放锁，可再次执行', () async {
      final handler = _CountingHandler();
      final lock = TaskLock();
      final executor = TaskExecutor(lock: lock);
      final task = _buildTask(handler: handler);
      const context = TaskContext(key: 'test-task', triggerType: TaskTriggerType.timer);

      await executor.execute(task, context);
      final second = await executor.execute(task, context);

      expect(second.status, TaskRunStatus.success);
      expect(handler.count, 2);
      expect(lock.isRunning('test-task'), isFalse);
    });
  });
}
