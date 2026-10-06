import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'message_sync_event.dart';

part 'message_sync_provider.g.dart';

@Riverpod(keepAlive: true)
class MessageSyncNotifier extends _$MessageSyncNotifier {
  final _syncEvents = StreamController<MessageSyncEvent>.broadcast();
  final _ackSyncEvents = StreamController<MessageAckSyncEvent>.broadcast();

  Stream<MessageSyncEvent> get syncEvents => _syncEvents.stream;

  Stream<MessageAckSyncEvent> get ackSyncEvents => _ackSyncEvents.stream;

  void emitSync(MessageSyncEvent event) => _syncEvents.add(event);

  void emitAckSync(MessageAckSyncEvent event) => _ackSyncEvents.add(event);

  @override
  void build() {
    ref.onDispose(_dispose);
  }

  void _dispose() {
    Future.wait([
      _syncEvents.close(),
      _ackSyncEvents.close(),
    ]);
  }
}
