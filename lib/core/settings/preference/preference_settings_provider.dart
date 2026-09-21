import 'package:clipshare/core/constants/default_settings_constants.dart';
import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/settings/preference/preference_settings.dart';
import 'package:clipshare/shared/enums/config_key.dart';
import 'package:clipshare/shared/extensions/string_extension.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'preference_settings_provider.g.dart';

@Riverpod(keepAlive: true)
Future<PreferenceSettings> preferenceSettings(Ref ref) async {
  final cfg = (await ref.read(appDbProvider.future)).configDao;
  final rememberWindowSize = await cfg.getConfigByKey(ConfigKey.rememberWindowSize, false);
  final windowSize = await cfg.getConfigByKey(
    ConfigKey.windowSize,
    defaultWindowSize,
    convert: (value) {
      if (rememberWindowSize) {
        try {
          final [width, height] = value.split('x').map((e) => e.toDouble()).toList();
          return Size(width, height);
        } catch (_) {
          return defaultWindowSize;
        }
      }
      return defaultWindowSize;
    },
  );
  final showOnRecentTasks = await cfg.getConfigByKey(ConfigKey.showOnRecentTasks, true);
  final showMoreItemsInRow = await cfg.getConfigByKey(ConfigKey.showMoreItemsInRow, true);
  final useTrayFlashingForConnection = await cfg.getConfigByKey(ConfigKey.useTrayFlashingForConnection, false);
  final recordHistoryDialogPosition = await cfg.getConfigByKey(ConfigKey.recordHistoryDialogPosition, false);
  final historyDialogPosition = await cfg.getConfigByKey(
    ConfigKey.historyDialogPosition,
    null,
    convert: (value) {
      if (value == '') {
        return null;
      }
      try {
        final [dx, dy] = value.split('x');
        return Offset(dx.toDouble(), dy.toDouble());
      } catch (_) {
        return null;
      }
    },
  );
  final historyWindowSize = await cfg.getConfigByKey(
    ConfigKey.historyWindowSize,
    null,
    convert: (value) {
      try {
        final [width, height] = value.split('x').map((e) => e.toDouble()).toList();
        return Size(width, height);
      } catch (_) {
        //ignored
      }
      return null;
    },
  );
  final rememberPopupWindowSize = await cfg.getConfigByKey(ConfigKey.rememberPopupWindowSize, false);
  final fileSenderWindowSize = await cfg.getConfigByKey(
    ConfigKey.fileSenderWindowSize,
    null,
    convert: (sizeStr) {
      try {
        final [width, height] = sizeStr.split("x").map((e) => e.toDouble()).toList();
        return Size(width, height);
      } catch (_) {
        //ignored
      }
      return null;
    },
  );
  final autoClosePopupOnBlur = await cfg.getConfigByKey(ConfigKey.autoClosePopupOnBlur, false);
  final closeOnSameHotKey = await cfg.getConfigByKey(ConfigKey.closeOnSameHotKey, false);
  final clickToPaste = await cfg.getConfigByKey(ConfigKey.clickToPaste, false);
  final lastSqlEditContent = await cfg.getConfigByKey(ConfigKey.lastSqlEditContent, '');

  return PreferenceSettings(
    rememberWindowSize: rememberWindowSize,
    windowSize: windowSize,
    showOnRecentTasks: showOnRecentTasks,
    showMoreItemsInRow: showMoreItemsInRow,
    useTrayFlashingForConnection: useTrayFlashingForConnection,
    recordHistoryDialogPosition: recordHistoryDialogPosition,
    historyDialogPosition: historyDialogPosition,
    historyWindowSize: historyWindowSize,
    rememberPopupWindowSize: rememberPopupWindowSize,
    fileSenderWindowSize: fileSenderWindowSize,
    autoClosePopupOnBlur: autoClosePopupOnBlur,
    closeOnSameHotKey: closeOnSameHotKey,
    clickToPaste: clickToPaste,
    lastSqlEditContent: lastSqlEditContent,
  );
}
