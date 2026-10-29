import 'dart:async';

import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/database/tables/operation_sync.dart';
import 'package:clipshare/core/services/transport/message_sender/message_sender_provider.dart';
import 'package:clipshare/core/services/transport/message_sync/message_sync_provider.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ack_sync_consumer_provider.g.dart';

/// 同步确认的统一收口。
///
/// 出站：本机处理成功的待确认事件在此统一发给对端
/// 入站：对端回传的同步确认在此记录到本地同步记录
@Riverpod(keepAlive: true)
class AckSyncConsumer extends _$AckSyncConsumer {
  static const tag = 'AckSyncConsumer';

  MessageSenderNotifier get _messageSender => ref.read(messageSenderProvider.notifier);

  @override
  void build() {
    final syncNotifier = ref.read(messageSyncProvider.notifier);
    unawaited(_sendPendingAcks(syncNotifier));
    unawaited(_storeIncomingAcks(syncNotifier));
  }

  Future<void> _sendPendingAcks(MessageSyncNotifier syncNotifier) async {
    await for (final event in syncNotifier.pendingAckEvents) {
      try {
        await _messageSender.sendToDevice(event.sender.guid, .ackSync, {
          'id': event.opId,
          'module': event.module.moduleName,
        });
      } catch (err, stack) {
        logger.error(tag, err, stack);
      }
    }
  }

  Future<void> _storeIncomingAcks(MessageSyncNotifier syncNotifier) async {
    await for (final event in syncNotifier.ackSyncEvents) {
      try {
        final db = await ref.read(appDbProvider.future);
        await db.operationSyncDao.add(
          newOperationSync(opId: event.opId, devId: event.sender.guid),
        );
      } catch (err, stack) {
        logger.error(tag, err, stack);
      }
    }
  }
}
