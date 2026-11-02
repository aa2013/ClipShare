import 'dart:async';

import 'package:clipshare/core/settings/forward/forward_server_status.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'forward_status_event_provider.g.dart';

/// 中转状态广播：中转服务与存储中转只负责发出事件，
/// 观察方通过 [ForwardStatusEventNotifier.forwardStatusEvents] 订阅。
@Riverpod(keepAlive: true)
class ForwardStatusEventNotifier extends _$ForwardStatusEventNotifier {
  final _controller = StreamController<ForwardServerStatus>.broadcast();

  /// 中转状态事件流，广播流可被多处同时订阅
  Stream<ForwardServerStatus> get forwardStatusEvents => _controller.stream;

  void emit(ForwardServerStatus status) {
    _controller.add(status);
  }

  @override
  void build() {
    ref.onDispose(_dispose);
  }

  void _dispose() {
    _controller.close();
  }
}
