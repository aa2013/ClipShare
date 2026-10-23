import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'app_update_settings.dart';

part 'app_update_settings_provider.g.dart';

/// 读取应用更新相关配置。
@Riverpod(keepAlive: true)
Future<AppUpdateSettings> appUpdateSettings(Ref ref) async {
  final cfg = (await ref.read(appDbProvider.future)).configDao;
  return AppUpdateSettings(
    ignoreUpdateVersion: await cfg.getConfigByKey(.ignoreUpdateVersion, null),
  );
}
