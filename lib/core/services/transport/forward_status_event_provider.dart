import 'dart:async';

import 'package:clipshare/core/settings/forward/forward_server_status.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'forward_status_event_provider.g.dart';

@Riverpod(keepAlive: true)
class ForwardStatusEventNotifier extends _$ForwardStatusEventNotifier {
  final _controller = StreamController<ForwardServerStatus>.broadcast();

  @override
  Stream<ForwardServerStatus> build() {
    return _controller.stream;
  }

  void addEvent(ForwardServerStatus status) {
    _controller.add(status);
  }
}
