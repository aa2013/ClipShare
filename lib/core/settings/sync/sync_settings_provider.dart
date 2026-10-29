import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'sync_settings.dart';

part 'sync_settings_provider.g.dart';

@Riverpod(keepAlive: true)
Future<SyncSettings> syncSettings(Ref ref) async {
  final cfg = (await ref.read(appDbProvider.future)).configDao;
  return SyncSettings(
    autoSyncMissingData: await cfg.getConfigByKey(.autoSyncMissingData, true),
    reCopyOnScreenUnlocked: await cfg.getConfigByKey(.recopyOnScreenUnlocked, false),
    saveToPictures: await cfg.getConfigByKey(.saveToPictures, false),
    autoCopyImageAfterSync: await cfg.getConfigByKey(.autoCopyImageAfterSync, false),
    autoCopyImageAfterScreenShot: await cfg.getConfigByKey(.autoCopyImageAfterScreenShot, true),
    syncOutdateLimitTime: await cfg.getConfigByKey(.syncOutdateLimitTime, 0),
  );
}
