import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'log_settings.dart';

part 'log_settings_provider.g.dart';

@Riverpod(keepAlive: true)
Future<LogSettings> logSettings(Ref ref) async {
  final cfg = (await ref.read(appDbProvider.future)).configDao;
  final settings = LogSettings(
    enableLogsRecord: await cfg.getConfigByKey(.enableLogsRecord, false),
    enableAutoUploadCrashLogs: await cfg.getConfigByKey(.enableAutoUploadCrashLogs, false),
  );
  // 日志落盘开关随配置同步到全局 logger，设置页切换 invalidate 后即时生效
  if (settings.enableLogsRecord) {
    logger.enable();
  } else {
    logger.disable();
  }
  return settings;
}
