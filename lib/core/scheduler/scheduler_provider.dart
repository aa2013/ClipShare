import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/scheduler/scheduler.dart';
import 'package:clipshare/core/scheduler/task_executor.dart';
import 'package:clipshare/core/scheduler/task_state_store.dart';
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
