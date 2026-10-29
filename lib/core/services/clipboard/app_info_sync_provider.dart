import 'dart:async';

import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/database/dao/app_info_dao.dart';
import 'package:clipshare/core/services/clipboard/clipboard_source_provider.dart';
import 'package:clipshare/core/services/transport/message_sync/message_sync_event.dart';
import 'package:clipshare/core/services/transport/message_sync/message_sync_provider.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_info_sync_provider.g.dart';

/// App 来源信息同步处理器。
@Riverpod(keepAlive: true)
class AppInfoSyncNotifier extends _$AppInfoSyncNotifier {
  static const tag = 'AppInfoSyncNotifier';

  MessageSyncNotifier get _syncNotifier => ref.read(messageSyncProvider.notifier);

  AppInfoDao get _appInfoDao => ref.read(appDbProvider).requireValue.appInfoDao;

  ClipboardSourceNotifier get _sourceNotifier => ref.read(clipboardSourceProvider.notifier);

  @override
  void build() {
    unawaited(_listenSyncEvents());
  }

  /// 监听来源信息同步事件，应用成功后回传确认。
  Future<void> _listenSyncEvents() async {
    await for (final event in _syncNotifier.syncEvents) {
      try {
        if (event is! AppInfoSyncEvent) {
          continue;
        }
        if (!await _apply(event)) {
          continue;
        }
        _syncNotifier.emitPendingAckFor(event);
      } catch (err, stack) {
        logger.error(tag, err, stack);
      }
    }
  }

  /// 处理app信息同步事件
  Future<bool> _apply(AppInfoSyncEvent event) async {
    switch (event.method) {
      case .add:
      case .update:
        final appInfo = event.appInfo;
        final local = await _appInfoDao.getByUniqueIndex(appInfo.devId, appInfo.appId);
        final value = local == null ? appInfo : appInfo.copyWith(id: local.id);
        return _sourceNotifier.addOrUpdate(value, false);
      case .delete:
      case .unknown:
        return false;
    }
  }
}
