import 'package:clipshare/core/runtime/app_state/app_state.dart';
import 'package:clipshare/core/runtime/app_state/app_state_provider.dart';
import 'package:clipshare/core/runtime/app_update/app_update_provider.dart';
import 'package:clipshare/core/scheduler/models/scheduled_task.dart';
import 'package:clipshare/core/scheduler/models/task_result.dart';
import 'package:clipshare/core/scheduler/scheduler.dart';
import 'package:clipshare/core/scheduler/scheduler_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// 只记录注册请求，便于断言注册时机与任务配置。
class _FakeScheduler implements Scheduler {
  final tasks = <ScheduledTask>[];

  /// 可注入注册失败，用于验证单个任务异常不向外抛出。
  Object? registerError;

  @override
  Future<TaskHandle> register(ScheduledTask task) async {
    final error = registerError;
    if (error != null) {
      throw error;
    }
    tasks.add(task);
    return TaskHandle(() async {});
  }

  @override
  bool isRegistered(String key) => tasks.any((task) => task.key == key);

  @override
  Future<TaskResult> runNow(String key) async => TaskResult.skipped(key, 'unused');

  @override
  void dispose() {}
}

/// 隔离设备网络监听，只暴露 UI 就绪状态的控制入口。
class _StateNotifier extends AppStateNotifier {
  @override
  AppState build() => const AppState();
}

/// 构造只覆盖调度器与运行时状态的容器，避免访问数据库与网络。
ProviderContainer _container(_FakeScheduler scheduler) {
  return ProviderContainer(overrides: [
    schedulerProvider.overrideWith((ref) async => scheduler),
    appStateProvider.overrideWith(_StateNotifier.new),
  ]);
}

/// 验证注册表只在 UI 就绪后注册且保持幂等。
void main() {
  test('UI 就绪前不注册任务', () async {
    final scheduler = _FakeScheduler();
    final container = _container(scheduler);
    container.listen(schedulerRegistryProvider, (_, _) {});
    final appState = container.read(appStateProvider.notifier);
    appState.updateInitStatus(AppInitStatus.initialized);
    await container.read(schedulerRegistryProvider.future);
    await Future<void>.delayed(Duration.zero);
    expect(scheduler.tasks, isEmpty);
    container.dispose();
  });

  test('进入 uiReady 后注册更新检查任务', () async {
    final scheduler = _FakeScheduler();
    final container = _container(scheduler);
    container.listen(schedulerRegistryProvider, (_, _) {});
    await container.read(schedulerRegistryProvider.future);
    final appState = container.read(appStateProvider.notifier);
    appState.updateInitStatus(AppInitStatus.initialized);
    appState.updateInitStatus(AppInitStatus.uiReady);
    await Future<void>.delayed(Duration.zero);
    final task = scheduler.tasks.single;
    expect(task.key, AppUpdateNotifier.automaticTaskKey);
    expect(task.runImmediately, isTrue);
    expect(task.runOnMissed, isFalse);
    final now = DateTime(2026);
    expect(task.schedule.nextRun(now), now.add(AppUpdateNotifier.automaticInterval));
    container.dispose();
  });

  test('重复进入 uiReady 不会重复注册', () async {
    final scheduler = _FakeScheduler();
    final container = _container(scheduler);
    container.listen(schedulerRegistryProvider, (_, _) {});
    await container.read(schedulerRegistryProvider.future);
    final appState = container.read(appStateProvider.notifier);
    appState.updateInitStatus(AppInitStatus.uiReady);
    await Future<void>.delayed(Duration.zero);
    // 状态回退后再次进入就绪，注册表应忽略这轮回退
    appState.updateInitStatus(AppInitStatus.initialized);
    appState.updateInitStatus(AppInitStatus.uiReady);
    await Future<void>.delayed(Duration.zero);
    expect(scheduler.tasks.length, 1);
    container.dispose();
  });

  test('注册失败不向外抛出', () async {
    final scheduler = _FakeScheduler()..registerError = StateError('register failed');
    final container = _container(scheduler);
    container.listen(schedulerRegistryProvider, (_, _) {});
    await container.read(schedulerRegistryProvider.future);
    container.read(appStateProvider.notifier).updateInitStatus(AppInitStatus.uiReady);
    await Future<void>.delayed(Duration.zero);
    expect(scheduler.tasks, isEmpty);
    container.dispose();
  });
}
