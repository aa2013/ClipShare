import 'package:clipshare/core/runtime/app_update/enums/app_update_check_status.dart';
import 'package:clipshare/shared/models/update_log.dart';

/// 一次检查的结果快照，失败保留原始异常与堆栈。
class AppUpdateCheckResult {
  final AppUpdateCheckStatus status;
  final List<UpdateLog> logs;
  final Object? error;
  final StackTrace? stackTrace;
  final bool forceCheck;

  const AppUpdateCheckResult({
    required this.status,
    this.logs = const [],
    this.error,
    this.stackTrace,
    this.forceCheck = false,
  });
}
