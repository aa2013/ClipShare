import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/providers/settings/clipboard/clipboard_settings.dart';
import 'package:clipshare/shared/enums/config_key.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:clipshare_clipboard_listener/enums.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'clipboard_settings_provider.g.dart';

const _tag = 'clipboardSettingsProvider';

/// 读取剪贴板相关配置。
@Riverpod(keepAlive: true)
Future<ClipboardSettings> clipboardSettings(Ref ref) async {
  final db = await ref.watch(appDbProvider.future);
  final configDao = db.configDao;
  return ClipboardSettings(
    stopListeningOnScreenClosed: await configDao.getConfigByKey(
      ConfigKey.stopListeningOnScreenClosed,
      false,
    ),
    sourceRecord: await configDao.getConfigByKey(ConfigKey.sourceRecord, false),
    sourceRecordViaDumpsys: await configDao.getConfigByKey(
      ConfigKey.sourceRecordViaDumpsys,
      false,
    ),
    sendBroadcastOnAdd: await configDao.getConfigByKey(
      ConfigKey.sendBroadcastOnAdd,
      false,
    ),
    isExcludeFormat: await configDao.getConfigByKey(ConfigKey.excludeFormat, true),
    recordMaxLength: await configDao.getConfigByKey(
      ConfigKey.recordMaxLength,
      200000,
    ),
    workingMode: await configDao.getConfigByKey(
      ConfigKey.workingMode,
      EnvironmentType.none,
      convert: _parseEnvironmentType,
    ),
    listeningWay: await configDao.getConfigByKey(
      ConfigKey.clipboardListeningWay,
      ClipboardListeningWay.logs,
      convert: _parseClipboardListeningWay,
    ),
  );
}

/// 解析 Android 剪贴板工作环境，非法配置回退到未选择状态。
EnvironmentType _parseEnvironmentType(String value) {
  try {
    return EnvironmentType.values.byName(value);
  } catch (err, stack) {
    logger.error(_tag, err, stack);
    return EnvironmentType.none;
  }
}

/// 解析 Android 剪贴板监听方式，非法配置回退到系统日志方式。
ClipboardListeningWay _parseClipboardListeningWay(String value) {
  try {
    return ClipboardListeningWay.values.byName(value);
  } catch (err, stack) {
    logger.error(_tag, err, stack);
    return ClipboardListeningWay.logs;
  }
}
