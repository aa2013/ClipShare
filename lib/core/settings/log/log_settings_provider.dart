import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'log_settings.dart';

part 'log_settings_provider.g.dart';

@Riverpod(keepAlive: true)
Future<LogSettings> logSettings(Ref ref) async {
  final cfg = (await ref.read(appDbProvider.future)).configDao;
  return LogSettings(
    enableLogsRecord: await cfg.getConfigByKey(.enableLogsRecord, false),
    enableAutoUploadCrashLogs: await cfg.getConfigByKey(.enableAutoUploadCrashLogs, false),
  );
}
