import 'package:clipshare/core/scheduler/models/task_context.dart';

/// 任务执行体统一接口
abstract class TaskHandler {
  const TaskHandler();

  /// 执行任务主体逻辑，抛出的异常由执行器捕获并按失败处理
  Future<void> run(TaskContext context);
}
