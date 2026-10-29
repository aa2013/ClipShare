import 'dart:async';

import 'package:clipshare/shared/utils/log.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'message_sync_event.dart';

part 'message_sync_provider.g.dart';

@Riverpod(keepAlive: true)
class MessageSyncNotifier extends _$MessageSyncNotifier {
  static const tag = 'MessageSyncNotifier';

  final _syncEvents = StreamController<MessageSyncEvent>.broadcast();
  final _ackSyncEvents = StreamController<MessageAckSyncEvent>.broadcast();
  final _pendingAckEvents = StreamController<MessageAckSyncEvent>.broadcast();
  final _missingDataBatchEvents = StreamController<MissingDataBatchEvent>.broadcast();

  /// 已解析出数据同步协议事件流
  Stream<MessageSyncEvent> get syncEvents => _syncEvents.stream;

  /// 对端回传的同步确认事件流
  Stream<MessageAckSyncEvent> get ackSyncEvents => _ackSyncEvents.stream;

  /// 本机已处理完毕、待发往对端的确认事件。
  ///
  /// 本流由模块处理成功后产出，统一由确认发送方消费
  Stream<MessageAckSyncEvent> get pendingAckEvents => _pendingAckEvents.stream;

  /// 缺失数据批量补数的进度事件流
  Stream<MissingDataBatchEvent> get missingDataBatchEvents => _missingDataBatchEvents.stream;

  void emitSync(MessageSyncEvent event) => _syncEvents.add(event);

  void emitAckSync(MessageAckSyncEvent event) => _ackSyncEvents.add(event);

  void emitMissingDataBatch(String devId, int seq, int total) {
    _missingDataBatchEvents.add(
      MissingDataBatchEvent(
        devId: devId,
        seq: seq,
        total: total,
      ),
    );
  }

  /// 按模块生成并投递待发送的确认事件。
  void emitPendingAckFor(MessageSyncEvent event) {
    final ackEvent = ackEventFor(event);
    if (ackEvent == null) {
      logger.warn(tag, 'no ack event for module=${event.module.name}');
      return;
    }
    _pendingAckEvents.add(ackEvent);
  }

  @override
  void build() {
    ref.onDispose(_dispose);
  }

  void _dispose() {
    Future.wait([
      _syncEvents.close(),
      _ackSyncEvents.close(),
      _pendingAckEvents.close(),
      _missingDataBatchEvents.close(),
    ]);
  }
}
