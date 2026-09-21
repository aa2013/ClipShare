import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'notification_settings.dart';

part 'notification_settings_provider.g.dart';

@Riverpod(keepAlive: true)
Future<NotificationSettings> notificationSettings(Ref ref) async {
  final cfg = (await ref.read(appDbProvider.future)).configDao;
  return NotificationSettings(
    enableRecordNotification: await cfg.getConfigByKey(.enableRecordNotification, false),
    notifyOnDevConn: await cfg.getConfigByKey(.notifyOnDevConn, true),
    notifyOnDevDisconn: await cfg.getConfigByKey(.notifyOnDevDisconn, true),
    enableShowMobileNotification: await cfg.getConfigByKey(.enableShowMobileNotification, false),
    notifyOnReceivedFile: await cfg.getConfigByKey(.notifyOnReceivedFile, false),
  );
}
