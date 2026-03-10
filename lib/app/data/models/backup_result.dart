import 'package:clipshare/app/data/models/exception_info.dart';

class BackupResult {
  final bool success;
  final String? localPath;
  final ExceptionInfo? exception;

  BackupResult({required this.success, required this.localPath, required this.exception});
}
