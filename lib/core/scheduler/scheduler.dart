import 'dart:async';

import 'package:clipshare/core/scheduler/enums/task_run_status.dart';
import 'package:clipshare/core/scheduler/enums/task_trigger_type.dart';
import 'package:clipshare/core/scheduler/models/scheduled_task.dart';
import 'package:clipshare/core/scheduler/models/task_context.dart';
import 'package:clipshare/core/scheduler/models/task_result.dart';
import 'package:clipshare/core/scheduler/models/task_state.dart';
import 'package:clipshare/core/scheduler/task_executor.dart';
import 'package:clipshare/core/scheduler/task_state_store.dart';
import 'package:clipshare/shared/utils/log.dart';

/// 任务注册句柄，由注册方持有并在任务下线时调用 [cancel]。
class TaskHandle {
  /// 注销回调，由调度内核注入
  final Future<void> Function() _onCancel;

  bool _cancelled = false;

  TaskHandle(this._onCancel);

  /// 是否已注销
  bool get cancelled => _cancelled;

  /// 注销任务：取消定时器并移除注册项，持久化状态保留。
  Future<void> cancel() async {
    if (_cancelled) {
      return;
    }
    _cancelled = true;
    await _onCancel();
  }
}

/// 调度内核对外能力。
abstract class Scheduler {
  /// 注册任务并返回注销句柄；同 key 重复注册会覆盖旧任务。
  Future<TaskHandle> register(ScheduledTask task);

  /// 立即执行一次已注册任务
  Future<TaskResult> runNow(String key);

  /// 任务是否已注册
  bool isRegistered(String key);

  /// 释放全部任务与定时器
  void dispose();
}

/// 调度内核实现：负责任务注册、下一跳计算、错过补跑与定时触发。
class SchedulerImpl implements Scheduler {
  static const tag = 'Scheduler';

  final TaskExecutor executor;

  final TaskStateStore stateStore;

  /// 时间源，便于测试注入固定时钟
  final DateTime Function() clock;

  final Map<String, _RegisteredTask> _tasks = <String, _RegisteredTask>{};

  bool _disposed = false;

  SchedulerImpl({
    required this.executor,
    required this.stateStore,
    DateTime Function()? clock,
  }) : clock = clock ?? DateTime.now;

  @override
  bool isRegistered(String key) {
    return _tasks.containsKey(key);
  }

  @override
  Future<TaskHandle> register(ScheduledTask task) async {
    final key = task.key;
    if (_disposed) {
      throw StateError('scheduler is disposed, cannot register task $key');
    }
    if (_tasks.containsKey(key)) {
      logger.warn(tag, "task '$key' already registered, replace it");
      _cancelTimer(key);
    }
    final registered = _RegisteredTask(task: task);
    _tasks[key] = registered;
    final now = clock();
    final state = await stateStore.read(key);
    registered.lastScheduledAt = state.lastScheduledAt;
    registered.lastRunAt = state.lastRunAt;
    if (task.runImmediately) {
      // 注册即执行不阻塞注册调用方，首次执行完成后再排下一跳
      unawaited(_runRegisterExecution(registered, now));
    } else {
      await _scheduleNext(registered, now);
    }
    logger.debug(tag, "task '$key' registered, runOnMissed=${task.runOnMissed}, runImmediately=${task.runImmediately}");
    return TaskHandle(() => _unregister(key));
  }

  @override
  Future<TaskResult> runNow(String key) async {
    final registered = _tasks[key];
    if (registered == null) {
      logger.warn(tag, "runNow ignored, task '$key' not registered");
      return TaskResult.skipped(key, 'task not registered');
    }
    return _execute(registered, TaskTriggerType.manual, null);
  }

  @override
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    for (final registered in _tasks.values) {
      registered.timer?.cancel();
      registered.timer = null;
    }
    _tasks.clear();
  }

  /// 注册后立即执行：先执行一次，再把计划点对齐到当前时间并排下一跳
  Future<void> _runRegisterExecution(_RegisteredTask registered, DateTime now) async {
    try {
      await _execute(registered, TaskTriggerType.register, null);
      await _advanceScheduledAt(registered, now);
      await _scheduleNext(registered, clock());
    } catch (err, stack) {
      logger.error(tag, "task '${registered.task.key}' register execution failed. $err", stack);
    }
  }

  /// 执行任务并同步状态中的上次执行时间。
  Future<TaskResult> _execute(_RegisteredTask registered, TaskTriggerType triggerType, DateTime? scheduledAt) async {
    final key = registered.task.key;
    final context = TaskContext(key: key, triggerType: triggerType, scheduledAt: scheduledAt);
    final result = await executor.execute(registered.task, context);
    if (result.status != TaskRunStatus.failed) {
      registered.lastRunAt = clock();
      await stateStore.write(key, TaskState(lastScheduledAt: registered.lastScheduledAt, lastRunAt: registered.lastRunAt));
    }
    return result;
  }

  /// 计算并设置下一次定时触发，触发点无法计算时停止该任务调度。
  Future<void> _scheduleNext(_RegisteredTask registered, DateTime now) async {
    if (_disposed) {
      return;
    }
    final key = registered.task.key;
    final lastScheduledAt = registered.lastScheduledAt;
    final missedTarget = lastScheduledAt == null ? null : registered.task.schedule.nextRun(lastScheduledAt);
    // 存在历史计划点且下一计划点已过去，说明停机期间跨过了计划点
    if (missedTarget != null && missedTarget.isBefore(now)) {
      await _handleMissed(registered, missedTarget, now);
      return;
    }
    final next = missedTarget ?? registered.task.schedule.nextRun(now);
    if (next == null) {
      logger.warn(tag, "task '$key' has no next run time, stop scheduling. schedule=${registered.task.schedule}");
      _cancelTimer(key);
      return;
    }
    _setTimer(registered, now, next);
  }

  /// 处理错过：按配置补跑一次，并把计划点推进到当前时间之前的最后一个计划点，
  /// 避免启动后连续补跑多轮造成负载堆积。
  Future<void> _handleMissed(_RegisteredTask registered, DateTime missedTarget, DateTime now) async {
    final task = registered.task;
    final key = task.key;
    final lastPlannedAt = _lastPlannedAtOrBefore(task, missedTarget, now);
    if (task.runOnMissed) {
      logger.info(tag, "task '$key' missed scheduled at $missedTarget, run once to catch up");
      await _execute(registered, TaskTriggerType.missed, missedTarget);
    } else {
      logger.info(tag, "task '$key' missed scheduled at $missedTarget, skip by config");
    }
    await _advanceScheduledAt(registered, lastPlannedAt);
    await _scheduleNext(registered, now);
  }

  /// 推进已处理计划点并持久化，不刷新上次执行时间。
  Future<void> _advanceScheduledAt(_RegisteredTask registered, DateTime scheduledAt) async {
    registered.lastScheduledAt = scheduledAt;
    await stateStore.write(registered.task.key, TaskState(lastScheduledAt: scheduledAt, lastRunAt: registered.lastRunAt));
  }

  /// 从 [from] 起向后推算，返回不晚于 [now] 的最后一个计划触发点。
  ///
  /// 用于把错过的多个计划点一次性折叠推进，只保留最后一跳，
  /// [maxSteps] 防止表达式异常导致无限循环。
  DateTime _lastPlannedAtOrBefore(ScheduledTask task, DateTime from, DateTime now, {int maxSteps = 10000}) {
    var current = from;
    var steps = 0;
    while (steps < maxSteps) {
      final next = task.schedule.nextRun(current);
      if (next == null || next.isAfter(now)) {
        break;
      }
      current = next;
      steps++;
    }
    return current;
  }

  /// 按计划触发点设置定时器，触发后重新计算下一跳。
  void _setTimer(_RegisteredTask registered, DateTime now, DateTime next) {
    final key = registered.task.key;
    registered.timer?.cancel();
    // 时间跳变导致 next 已过期时按最小延迟尽快执行，避免负时长
    final delay = next.difference(now);
    final safeDelay = delay.isNegative ? Duration.zero : delay;
    logger.debug(tag, "task '$key' next run at $next (in ${safeDelay.inSeconds}s)");
    registered.timer = Timer(safeDelay, () => _onTimer(registered, next));
  }

  /// 定时器回调：更新已处理计划点后执行任务，再排下一跳。
  ///
  /// 回调内异常必须在此捕获，否则会变成未处理的异步错误，导致后续任务不再排期。
  Future<void> _onTimer(_RegisteredTask registered, DateTime scheduledAt) async {
    if (_disposed) {
      return;
    }
    final key = registered.task.key;
    try {
      await _advanceScheduledAt(registered, scheduledAt);
      await _execute(registered, TaskTriggerType.timer, scheduledAt);
      await _scheduleNext(registered, clock());
    } catch (err, stack) {
      logger.error(tag, "task '$key' timer callback failed. $err", stack);
    }
  }

  /// 取消任务定时器。
  void _cancelTimer(String key) {
    final registered = _tasks[key];
    registered?.timer?.cancel();
    registered?.timer = null;
  }

  /// 注销任务：移除注册项并取消定时器。
  Future<void> _unregister(String key) async {
    final registered = _tasks.remove(key);
    if (registered == null) {
      return;
    }
    registered.timer?.cancel();
    registered.timer = null;
    logger.debug(tag, "task '$key' unregistered");
  }
}

/// 已注册任务的运行期信息，仅内核内部使用。
class _RegisteredTask {
  final ScheduledTask task;

  /// 当前定时器，无定时任务时为 null
  Timer? timer;

  /// 上次已处理的计划触发点
  DateTime? lastScheduledAt;

  /// 上次实际执行时间
  DateTime? lastRunAt;

  _RegisteredTask({required this.task});
}
