import 'dart:async';

import 'history_event.dart';

class HistoryRecorder {
  final _controller = StreamController<ClipboardHistoryEvent>.broadcast();

  /// 下游订阅此 Stream 获取已处理的事件
  Stream<ClipboardHistoryEvent> get events => _controller.stream;

  Future<void> add(ClipboardHistoryEvent event) async {
    _controller.add(event);
  }

  void dispose() {
    _controller.close();
  }
}
