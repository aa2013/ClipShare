import 'package:clipshare/core/constants/default_settings_constants.dart';
import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/settings/hotkey/hotkey_settings.dart';
import 'package:clipshare/shared/enums/config_key.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'hotkey_settings_provider.g.dart';

@Riverpod(keepAlive: true)
Future<HotkeySettings> hotkeySettings(Ref ref) async {
  final cfg = (await ref.read(appDbProvider.future)).configDao;
  final takeOverWinV = await cfg.getConfigByKey(ConfigKey.takeOverWinV, false);
  final restoreWinVOnExit = await cfg.getConfigByKey(ConfigKey.restoreWinVOnExit, true);
  final historyWindowHotKeys = await cfg.getConfigByKey(ConfigKey.historyWindowHotKeys, defaultHistoryWindowKeys);
  final syncFileHotKeys = await cfg.getConfigByKey(ConfigKey.syncFileHotKeys, defaultSyncFileHotKeys);
  final showMainWindows = await cfg.getConfigByKey(ConfigKey.showMainWindowHotKeys, '');
  final exitAppHotKeys = await cfg.getConfigByKey(ConfigKey.exitAppHotKeys, '');

  return HotkeySettings(
    takeOverWinV: takeOverWinV,
    restoreWinVOnExit: restoreWinVOnExit,
    historyWindowHotKeys: historyWindowHotKeys,
    syncFileHotKeys: syncFileHotKeys,
    showMainWindows: showMainWindows,
    exitAppHotKeys: exitAppHotKeys,
  );
}
