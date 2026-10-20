import 'dart:async';

import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/database/tables/operation_sync.dart';
import 'package:clipshare/core/services/transport/enums/msg_type.dart';
import 'package:clipshare/core/services/transport/message_sender/message_sender_provider.dart';
import 'package:clipshare/core/services/transport/message_sync/message_sync_event.dart';
import 'package:clipshare/core/services/transport/message_sync/message_sync_provider.dart';
import 'package:clipshare/shared/models/module.dart';
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
      final module = _moduleOf(event);
      try {
        await _messageSender.sendToDevice(event.sender.guid, .ackSync, {
          'id': event.opId,
          'module': module.moduleName,
        });
      } catch (err, stack) {
        logger.error(tag, err, stack);
      }
    }
  }

  Future<void> _storeIncomingAcks(MessageSyncNotifier syncNotifier) async {
    final db = await ref.read(appDbProvider.future);
    await for (final event in syncNotifier.ackSyncEvents) {
      try {
        await db.operationSyncDao.add(
          newOperationSync(opId: event.opId, devId: event.sender.guid),
        );
      } catch (err, stack) {
        logger.error(tag, err, stack);
      }
    }
  }

  /// 确认事件按模块细分，发送时需要还原成协议中的模块名。
  Module _moduleOf(MessageAckSyncEvent event) => switch (event) {
    DeviceAckSyncEvent() => Module.device,
    HistoryAckSyncEvent() => Module.history,
    HistoryTopAckSyncEvent() => Module.historyTop,
    HistorySourceAckSyncEvent() => Module.historySource,
    HistoryTagAckSyncEvent() => Module.tag,
    AppInfoAckSyncEvent() => Module.appInfo,
    RuleAckSyncEvent() => Module.rule,
    ScriptModuleAckSyncEvent() => Module.scriptModule,
  };
}
