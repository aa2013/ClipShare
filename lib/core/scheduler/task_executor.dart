import 'dart:async';

import 'package:clipshare/core/scheduler/models/scheduled_task.dart';
import 'package:clipshare/core/scheduler/models/task_context.dart';
import 'package:clipshare/core/scheduler/models/task_result.dart';
import 'package:clipshare/core/scheduler/task_lock.dart';
import 'package:clipshare/shared/utils/log.dart';

/// 任务执行器：统一处理互斥、超时、异常捕获与执行日志
class TaskExecutor {
  static const tag = 'TaskExecutor';

  final TaskLock lock;

  TaskExecutor({TaskLock? lock}) : lock = lock ?? TaskLock();

  /// 执行一次任务，任何异常都会转换为失败结果，不向调用方抛出。
  Future<TaskResult> execute(ScheduledTask task, TaskContext context) async {
    final key = task.key;
    if (!lock.tryAcquire(key)) {
      if (task.skipIfRunning) {
        logger.debug(tag, "task '$key' still running, skip trigger=${context.triggerType.name}");
        return TaskResult.skipped(key, 'previous run still running');
      }
      // 不跳过并发时等待上一轮结束再执行，避免同一任务并行修改数据。
      while (lock.isRunning(key)) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      if (!lock.tryAcquire(key)) {
        return TaskResult.skipped(key, 'acquire lock failed');
      }
    }
    final startedAt = DateTime.now();
    try {
      await _runWithTimeout(task, context);
      final elapsed = DateTime.now().difference(startedAt);
      logger.debug(tag, "task '$key' success, trigger=${context.triggerType.name}, elapsed=${elapsed.inMilliseconds}ms");
      return TaskResult.success(key, elapsed);
    } catch (err, stack) {
      final elapsed = DateTime.now().difference(startedAt);
      logger.error(tag, "task '$key' failed, trigger=${context.triggerType.name}, error=$err", stack);
      return TaskResult.failed(key, elapsed, err.toString());
    } finally {
      lock.release(key);
    }
  }

  /// 执行任务主体，配置了超时时间时超时即按失败处理。
  Future<void> _runWithTimeout(ScheduledTask task, TaskContext context) {
    final timeout = task.timeout;
    final future = Future<void>.sync(() => task.handler.run(context));
    if (timeout == null) {
      return future;
    }
    return future.timeout(
      timeout,
      onTimeout: () {
        throw TimeoutException("task '${task.key}' exceeded ${timeout.inMilliseconds}ms");
      },
    );
  }
}
