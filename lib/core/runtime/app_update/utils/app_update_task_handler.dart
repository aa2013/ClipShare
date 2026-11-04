import 'package:clipshare/core/runtime/app_update/enums/app_update_check_status.dart';
import 'package:clipshare/core/runtime/app_update/models/app_update_check_result.dart';
import 'package:clipshare/core/scheduler/models/task_context.dart';
import 'package:clipshare/core/scheduler/task_handler.dart';

/// 将更新检查接入调度器
class AppUpdateTaskHandler extends TaskHandler {
  final Future<AppUpdateCheckResult> Function() check;

  const AppUpdateTaskHandler(this.check);

  /// 执行自动检查，失败使用原始异常与堆栈交给调度器记录。
  @override
  Future<void> run(TaskContext context) async {
    final result = await check();
    if (result.status == .failed) {
      Error.throwWithStackTrace(result.error!, result.stackTrace!);
    }
  }
}
