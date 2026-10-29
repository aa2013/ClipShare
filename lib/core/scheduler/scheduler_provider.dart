import 'dart:async';

import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/runtime/app_state/app_state.dart';
import 'package:clipshare/core/runtime/app_state/app_state_provider.dart';
import 'package:clipshare/core/runtime/app_update/app_update_provider.dart';
import 'package:clipshare/core/scheduler/models/scheduled_task.dart';
import 'package:clipshare/core/scheduler/schedule/cron_schedule.dart';
import 'package:clipshare/core/scheduler/schedule/interval_schedule.dart';
import 'package:clipshare/core/scheduler/schedule/simple_task_handler.dart';
import 'package:clipshare/core/scheduler/scheduler.dart';
import 'package:clipshare/core/scheduler/task_executor.dart';
import 'package:clipshare/core/scheduler/task_state_store.dart';
import 'package:clipshare/shared/extensions/number_extension.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'scheduler_provider.g.dart';

/// 全局调度器，其他 provider 按需注册/注销任务
@Riverpod(keepAlive: true)
Future<Scheduler> scheduler(Ref ref) async {
  final db = await ref.read(appDbProvider.future);
  final stateStore = TaskStateStore(db.configDao);
  final instance = SchedulerImpl(executor: TaskExecutor(), stateStore: stateStore);
  ref.onDispose(instance.dispose);
  return instance;
}

/// App 内固定定时任务的统一注册入口。
///
/// 等 UI 就绪（[AppInitStatus.uiReady]）后再注册，保证任务首次执行时页面、弹窗与导航栈已可用；
/// 任务释放由 [SchedulerImpl.dispose] 统一完成，此处无需额外的注销处理。
@Riverpod(keepAlive: true)
Future<void> schedulerRegistry(Ref ref) async {
  final scheduler = await ref.read(schedulerProvider.future);
  // 注册只执行一次：状态在就绪与初始化之间回退时会再次满足条件，避免重复注册
  var registered = false;
  Future<void> registerOnce() async {
    if (registered) {
      return;
    }
    registered = true;
    await _registerAll(ref, scheduler);
  }

  // 重启后的重建场景可能已就绪，直接注册；冷启动则等待状态迁移
  if (_isUiReady(ref.read(appStateProvider))) {
    await registerOnce();
    return;
  }
  ref.listen<AppState>(appStateProvider, (previous, next) {
    if (_isUiReady(previous) || !_isUiReady(next)) {
      return;
    }
    unawaited(registerOnce());
  });
}

/// 判断状态是否已到达 UI 就绪，[value] 为空视为未就绪。
bool _isUiReady(AppState? value) {
  return value?.initStatus == AppInitStatus.uiReady;
}

/// 注册全部固定任务；单个任务失败不影响其余任务。
Future<void> _registerAll(Ref ref, Scheduler scheduler) async {
  // 固定任务清单：新增任务时在此追加
  final tasks = <ScheduledTask>[
    _buildAppUpdateTask(ref),
    _buildLogCleanupTask(),
  ];
  logger.debug(SchedulerImpl.tag, 'register fixed tasks: ${tasks.map((item) => item.key).join(', ')}');
  for (final task in tasks) {
    try {
      await scheduler.register(task);
    } catch (err, stack) {
      logger.error(SchedulerImpl.tag, "register task '${task.key}' failed. $err", stack);
    }
  }
}

/// 应用更新检查任务：注册即检查一次，之后按固定周期轮询。
///
/// 检查结果以异常形式上报，交由调度器按失败记录。
ScheduledTask _buildAppUpdateTask(Ref ref) {
  return ScheduledTask(
    key: AppUpdateNotifier.schedulerKey,
    schedule: const IntervalSchedule(AppUpdateNotifier.automaticInterval),
    handler: SimpleTaskHandler((_) async {
      final appUpdate = ref.read(appUpdateProvider.notifier);
      final result = await appUpdate.checkUpdate();
      if (result.status == .failed) {
        Error.throwWithStackTrace(result.error!, result.stackTrace!);
      }
    }),
    runImmediately: true,
    runOnMissed: false,
  );
}

/// 日志清理任务：每天零点触发并延迟一秒执行，启动时立即执行一次。
///
/// 停机期间跨过的零点不补跑，下一次零点照常清理。
ScheduledTask _buildLogCleanupTask() {
  return ScheduledTask(
    key: Log.schedulerKey,
    //每天 0 点执行
    schedule: CronSchedule('0 0 * * *'),
    handler: SimpleTaskHandler((_) async {
      await Future.delayed(1.s);
      await logger.cleanupLogs();
    }),
    runImmediately: true,
    runOnMissed: false,
  );
}
