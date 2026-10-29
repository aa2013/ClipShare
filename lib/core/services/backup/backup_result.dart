import 'package:clipshare/shared/models/exception_info.dart';

/// 备份执行结果
class BackupResult {
  final bool success;
  final String? localPath;
  final ExceptionInfo? exception;

  BackupResult({required this.success, required this.localPath, required this.exception});
}
