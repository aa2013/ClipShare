import 'dart:async';

import 'package:clipshare/core/services/tag/tag_provider.dart';
import 'package:clipshare/core/services/transport/message_sync/message_sync_event.dart';
import 'package:clipshare/core/services/transport/message_sync/message_sync_provider.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tag_sync_provider.g.dart';

/// 标签同步处理器。
@Riverpod(keepAlive: true)
class TagSyncNotifier extends _$TagSyncNotifier {
  static const tag = 'TagSyncNotifier';

  MessageSyncNotifier get _syncNotifier => ref.read(messageSyncProvider.notifier);

  TagNotifier get _tagNotifier => ref.read(tagProvider.notifier);

  @override
  void build() {
    unawaited(_listenSyncEvents());
  }

  Future<void> _listenSyncEvents() async {
    await for (final event in _syncNotifier.syncEvents) {
      try {
        if (event is! HistoryTagSyncEvent) {
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

  /// 处理应用标签同步事件
  Future<bool> _apply(HistoryTagSyncEvent event) async {
    final remote = event.tag;
    switch (event.method) {
      case .add:
        return _tagNotifier.applyRemoteAdd(remote);
      case .delete:
        return _tagNotifier.applyRemoteRemove(remote);
      case .update:
      case .unknown:
        return false;
    }
  }
}
