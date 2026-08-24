import 'dart:async';

import 'package:clipshare/core/clipboard/clipboard_history_event.dart';
import 'package:clipshare/core/clipboard/clipboard_service.dart';
import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/providers/app_state/app_state_provider.dart';
import 'package:clipshare/core/providers/local_device/local_device_info_provider.dart';
import 'package:clipshare/core/providers/settings/app_paths/app_paths_provider.dart';
import 'package:clipshare/core/providers/settings/clipboard/clipboard_settings_provider.dart';
import 'package:clipshare/core/providers/snowflake/id_provider.dart';
import 'package:clipshare/shared/enums/config_key.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'clipboard_service_provider.g.dart';

/// 剪贴板核心服务
@Riverpod(keepAlive: true)
Future<ClipboardService> clipboardService(Ref ref) async {
  final localDeviceInfo = await ref.read(localDeviceInfoProvider.future);
  final service = ClipboardService(
    loadSettings: () => ref.read(clipboardSettingsProvider.future),
    loadAppPaths: () => ref.read(appPathsProvider.future),
    readAppState: () => ref.read(appStateProvider),
    persistExcludeFormat: (enabled) async {
      final db = await ref.read(appDbProvider.future);
      await db.configDao.addOrUpdate(ConfigKey.excludeFormat, enabled.toString());
      ref.invalidate(clipboardSettingsProvider);
    },
    idGenerator: ref.read(idProvider),
    localDeviceInfo: localDeviceInfo,
  );
  ref.onDispose(service.dispose);
  await service.init();
  ref.listen(clipboardSettingsProvider, (previous, next) {
    final settings = next.asData?.value;
    if (settings != null) {
      unawaited(service.applySettings(settings));
    }
  });
  return service;
}

/// 剪贴板历史事件流
@Riverpod(keepAlive: true)
Stream<ClipboardHistoryEvent> clipboardHistoryEvents(Ref ref) async* {
  final service = await ref.watch(clipboardServiceProvider.future);
  yield* service.histories;
}
