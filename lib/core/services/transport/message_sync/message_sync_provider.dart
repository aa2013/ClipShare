import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'message_sync_event.dart';

part 'message_sync_provider.g.dart';

@Riverpod(keepAlive: true)
class MessageSyncNotifier extends _$MessageSyncNotifier {
  final _syncEvents = StreamController<MessageSyncEvent>.broadcast();
  final _ackSyncEvents = StreamController<MessageAckSyncEvent>.broadcast();
  final _pendingAckEvents = StreamController<MessageAckSyncEvent>.broadcast();

  /// 已解析出数据同步协议事件流
  Stream<MessageSyncEvent> get syncEvents => _syncEvents.stream;

  /// 对端回传的同步确认事件流
  Stream<MessageAckSyncEvent> get ackSyncEvents => _ackSyncEvents.stream;

  /// 本机已处理完毕、待发往对端的确认事件。
  ///
  /// 本流由模块处理成功后产出，统一由确认发送方消费
  Stream<MessageAckSyncEvent> get pendingAckEvents => _pendingAckEvents.stream;

  void emitSync(MessageSyncEvent event) => _syncEvents.add(event);

  void emitAckSync(MessageAckSyncEvent event) => _ackSyncEvents.add(event);

  void emitPendingAck(MessageAckSyncEvent event) => _pendingAckEvents.add(event);

  @override
  void build() {
    ref.onDispose(_dispose);
  }

  void _dispose() {
    Future.wait([
      _syncEvents.close(),
      _ackSyncEvents.close(),
      _pendingAckEvents.close(),
    ]);
  }
}
