import 'package:clipshare/core/database/tables/history.dart';
import 'package:clipshare/shared/models/op_method.dart';
import 'package:clipshare_clipboard_listener/models/clipboard_source.dart';

/// 原始历史事件。
class RawHistoryEvent {
  /// 历史记录
  final History history;

  /// 剪贴板来源识别结果
  final ClipboardSource? source;

  /// 是否同步数据
  final bool sync;

  const RawHistoryEvent({
    required this.history,
    required this.sync,
    this.source,
  });
}

///历史记录变更（主要是feature使用）
class HistoryDeltaEvent {
  /// 历史记录
  final History history;

  /// 操作方法
  final OpMethod _operation;

  bool get isAdd => _operation == OpMethod.add;

  bool get isDelete => _operation == OpMethod.delete;

  bool get isUpdate => _operation == OpMethod.update;

  const HistoryDeltaEvent({
    required this.history,
    required OpMethod operation,
  }) : _operation = operation;
}
