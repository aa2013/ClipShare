import 'package:clipshare/core/constants/app_constants.dart';
import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/settings/float/float_window_settings.dart';
import 'package:clipshare/shared/enums/config_key.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'float_window_settings_provider.g.dart';

@Riverpod(keepAlive: true)
Future<FloatWindowSettings> floatWindowSettings(Ref ref) async {
  final db = await ref.read(appDbProvider.future);
  final configDao = db.configDao;
  return FloatWindowSettings(
    enhanceBackgroundKeepAlive: await configDao.getConfigByKey(ConfigKey.enhanceBackgroundKeepAlive, false),
    showHistoryFloat: await configDao.getConfigByKey(ConfigKey.showHistoryFloat, false),
    lockHistoryFloatLoc: await configDao.getConfigByKey(ConfigKey.lockHistoryFloatLoc, true),
    historyFloatHandleWidth: await configDao.getConfigByKey(ConfigKey.historyFloatHandleWidth, 32),
    historyFloatHandleColor: await configDao.getConfigByKey(
      ConfigKey.historyFloatHandleColor,
      defaultHistoryFloatHandleColor,
    ),
    historyFloatHandleApplyAlphaToWholeHandle: await configDao.getConfigByKey(
      ConfigKey.historyFloatHandleApplyAlphaToWholeHandle,
      false,
    ),
    enablePIP: await configDao.getConfigByKey(ConfigKey.enablePIP, false),
  );
}
