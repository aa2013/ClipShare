import 'package:clipshare/core/database/tables/history.dart';
import 'package:clipshare_clipboard_listener/models/clipboard_source.dart';

/// 剪贴板历史事件。
class ClipboardHistoryEvent {
  /// 历史记录
  final History history;

  /// 剪贴板来源识别结果
  final ClipboardSource? source;

  const ClipboardHistoryEvent({
    required this.history,
    this.source,
  });
}
