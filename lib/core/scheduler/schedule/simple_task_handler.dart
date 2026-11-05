import 'package:clipshare/core/scheduler/models/task_context.dart';
import 'package:clipshare/core/scheduler/task_handler.dart';

/// 将普通异步回调适配为调度任务执行体，免去为一次性任务单独定义类。
class SimpleTaskHandler extends TaskHandler {

  final Future<void> Function(TaskContext context) callback;

  const SimpleTaskHandler(this.callback);

  @override
  Future<void> run(TaskContext context) => callback(context);
}
