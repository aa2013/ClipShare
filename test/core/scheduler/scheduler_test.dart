import 'package:clipshare/core/database/app_database.dart';
import 'package:clipshare/core/scheduler/enums/task_run_status.dart';
import 'package:clipshare/core/scheduler/enums/task_trigger_type.dart';
import 'package:clipshare/core/scheduler/models/scheduled_task.dart';
import 'package:clipshare/core/scheduler/models/task_context.dart';
import 'package:clipshare/core/scheduler/models/task_state.dart';
import 'package:clipshare/core/scheduler/schedule/schedule.dart';
import 'package:clipshare/core/scheduler/scheduler.dart';
import 'package:clipshare/core/scheduler/task_executor.dart';
import 'package:clipshare/core/scheduler/task_handler.dart';
import 'package:clipshare/core/scheduler/task_state_store.dart';
import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// 内存版状态存储，替代真实数据库持久化，便于直接断言状态推进结果。
class _MemoryStateStore extends TaskStateStore {
  final Map<String, TaskState> states = <String, TaskState>{};

  _MemoryStateStore() : super(AppDatabase(_MemoryExecutor.memory()).configDao);

  @override
  Future<TaskState> read(String key) async {
    return states[key] ?? const TaskState.empty();
  }

  @override
  Future<void> write(String key, TaskState state) async {
    states[key] = state;
  }
}

/// 仅用于构造 ConfigDao 的内存执行器，内存状态存储不会真正读写它。
class _MemoryExecutor {
  static DatabaseConnection memory() {
    return DatabaseConnection(NativeDatabase.memory());
  }
}

/// 记录执行的测试任务
class _RecordingHandler extends TaskHandler {
  final List<TaskTriggerType> triggers = <TaskTriggerType>[];

  int get count => triggers.length;

  @override
  Future<void> run(TaskContext context) async {
    triggers.add(context.triggerType);
  }
}

/// 固定间隔的测试调度策略，避免真实时钟影响判定
class _FixedSchedule implements Schedule {
  final Duration interval;

  const _FixedSchedule(this.interval);

  @override
  DateTime? nextRun(DateTime from) {
    return from.add(interval);
  }
}

SchedulerImpl _buildScheduler({
  required _MemoryStateStore store,
  required DateTime Function() clock,
}) {
  return SchedulerImpl(
    executor: TaskExecutor(),
    stateStore: store,
    clock: clock,
  );
}

ScheduledTask _buildTask({
  required TaskHandler handler,
  Duration interval = const Duration(hours: 1),
  bool runOnMissed = true,
  bool runImmediatelyOnRegister = false,
}) {
  return ScheduledTask(
    key: 'test-task',
    schedule: _FixedSchedule(interval),
    handler: handler,
    runOnMissed: runOnMissed,
    runImmediately: runImmediatelyOnRegister,
  );
}

void main() {
  group('SchedulerImpl 注册与注销', () {
    test('注册后 isRegistered 为 true，注销后为 false', () async {
      final store = _MemoryStateStore();
      final scheduler = _buildScheduler(store: store, clock: () => DateTime(2026, 1, 1, 8));

      final handle = await scheduler.register(_buildTask(handler: _RecordingHandler()));
      expect(scheduler.isRegistered('test-task'), isTrue);

      await handle.cancel();
      expect(scheduler.isRegistered('test-task'), isFalse);
      scheduler.dispose();
    });

    test('重复注册同一 key 覆盖旧任务且不抛异常', () async {
      final store = _MemoryStateStore();
      final scheduler = _buildScheduler(store: store, clock: () => DateTime(2026, 1, 1, 8));

      await scheduler.register(_buildTask(handler: _RecordingHandler()));
      final second = _RecordingHandler();
      await scheduler.register(_buildTask(handler: second));

      expect(scheduler.isRegistered('test-task'), isTrue);
      final result = await scheduler.runNow('test-task');
      expect(result.status, TaskRunStatus.success);
      expect(second.count, 1);
      scheduler.dispose();
    });

    test('runNow 对未注册任务返回 skipped', () async {
      final store = _MemoryStateStore();
      final scheduler = _buildScheduler(store: store, clock: () => DateTime(2026, 1, 1, 8));

      final result = await scheduler.runNow('unknown');

      expect(result.status, TaskRunStatus.skipped);
      scheduler.dispose();
    });

    test('dispose 后注册抛出 StateError', () async {
      final store = _MemoryStateStore();
      final scheduler = _buildScheduler(store: store, clock: () => DateTime(2026, 1, 1, 8));
      scheduler.dispose();

      expect(
        () => scheduler.register(_buildTask(handler: _RecordingHandler())),
        throwsStateError,
      );
    });
  });

  group('SchedulerImpl 错过判定', () {
    test('无历史状态时不判为错过，不补跑', () async {
      final store = _MemoryStateStore();
      final now = DateTime(2026, 1, 1, 8);
      final scheduler = _buildScheduler(store: store, clock: () => now);
      final handler = _RecordingHandler();

      await scheduler.register(_buildTask(handler: handler));

      expect(handler.count, 0);
      expect(store.states['test-task']?.lastScheduledAt, isNull);
      scheduler.dispose();
    });

    test('错过时补跑一次，并把计划点折叠推进到最后一跳', () async {
      final store = _MemoryStateStore();
      final now = DateTime(2026, 1, 1, 12);
      // 上次计划点为 08:00，周期 1 小时，停机期间跨过 09:00~12:00
      store.states['test-task'] = TaskState(lastScheduledAt: DateTime(2026, 1, 1, 8));
      final scheduler = _buildScheduler(store: store, clock: () => now);
      final handler = _RecordingHandler();

      await scheduler.register(_buildTask(handler: handler));

      expect(handler.count, 1);
      expect(handler.triggers.first, TaskTriggerType.missed);
      expect(store.states['test-task']?.lastScheduledAt, DateTime(2026, 1, 1, 12));
      scheduler.dispose();
    });

    test('runOnMissed 为 false 时只推进计划点不执行', () async {
      final store = _MemoryStateStore();
      final now = DateTime(2026, 1, 1, 12);
      store.states['test-task'] = TaskState(lastScheduledAt: DateTime(2026, 1, 1, 8));
      final scheduler = _buildScheduler(store: store, clock: () => now);
      final handler = _RecordingHandler();

      await scheduler.register(_buildTask(handler: handler, runOnMissed: false));

      expect(handler.count, 0);
      expect(store.states['test-task']?.lastScheduledAt, DateTime(2026, 1, 1, 12));
      scheduler.dispose();
    });

    test('时钟回拨不判为错过', () async {
      final store = _MemoryStateStore();
      final now = DateTime(2026, 1, 1, 6);
      // 上次计划点在“未来”，模拟时钟回拨
      store.states['test-task'] = TaskState(lastScheduledAt: DateTime(2026, 1, 1, 8));
      final scheduler = _buildScheduler(store: store, clock: () => now);
      final handler = _RecordingHandler();

      await scheduler.register(_buildTask(handler: handler));

      expect(handler.count, 0);
      scheduler.dispose();
    });
  });

  group('SchedulerImpl 注册即执行', () {
    test('开启后在注册后执行一次，并把计划点对齐到注册时间', () async {
      final store = _MemoryStateStore();
      final now = DateTime(2026, 1, 1, 8);
      final scheduler = _buildScheduler(store: store, clock: () => now);
      final handler = _RecordingHandler();

      await scheduler.register(_buildTask(handler: handler, runImmediatelyOnRegister: true));
      // 注册执行走异步任务，等待微任务与 IO 回调完成
      await Future<void>.delayed(const Duration(milliseconds: 0));

      expect(handler.count, 1);
      expect(handler.triggers.first, TaskTriggerType.register);
      expect(store.states['test-task']?.lastScheduledAt?.isAtSameMomentAs(now), isTrue);
      scheduler.dispose();
    });

    test('默认不开启注册即执行', () async {
      final store = _MemoryStateStore();
      final scheduler = _buildScheduler(store: store, clock: () => DateTime(2026, 1, 1, 8));
      final handler = _RecordingHandler();

      await scheduler.register(_buildTask(handler: handler));
      await Future<void>.delayed(const Duration(milliseconds: 0));

      expect(handler.count, 0);
      scheduler.dispose();
    });
  });
}
