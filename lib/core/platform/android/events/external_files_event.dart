import 'package:desktop_drop/desktop_drop.dart';

/// 外部进入应用的文件事件：系统分享与系统打开的文件归一化批次
class ExternalFilesEvent {
  /// 可解析为待发送条目的原始文件集合（本地路径或 content uri）
  final List<DropItem> files;

  const ExternalFilesEvent(this.files);
}
