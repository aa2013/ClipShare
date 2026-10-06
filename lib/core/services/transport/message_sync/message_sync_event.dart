import 'dart:typed_data';

import 'package:clipshare/core/database/app_database.dart';
import 'package:clipshare/core/services/device/local_device_info.dart';
import 'package:clipshare/shared/enums/sync_source.dart';
import 'package:clipshare/shared/models/op_method.dart';

/// 数据同步事件。
sealed class MessageSyncEvent {
  /// 发送该操作的设备
  final BaseDeviceInfo sender;

  /// 操作类型
  final OpMethod method;

  /// 操作记录 id
  final int opId;

  /// 操作记录事件
  final String time;

  ///同步来源
  final SyncSource source;

  const MessageSyncEvent({
    required this.sender,
    required this.method,
    required this.opId,
    required this.time,
    required this.source,
  });

  bool? get storageSync => switch (source) {
    SyncSource.storage || SyncSource.storageMissing => true,
    SyncSource.direct || SyncSource.missingData => null,
  };
}

/// 同步确认事件，发送端据此标记对端已消费指定操作。
sealed class MessageAckSyncEvent {
  /// 回 ack 的设备
  final BaseDeviceInfo sender;

  /// 被确认的发送端 OperationRecord.id
  final int opId;

  const MessageAckSyncEvent({required this.sender, required this.opId});
}

/// 设备元数据同步
class DeviceSyncEvent extends MessageSyncEvent {
  final Device device;

  const DeviceSyncEvent({
    required super.sender,
    required super.method,
    required super.opId,
    required super.time,
    required super.source,
    required this.device,
  });
}

/// 历史记录同步（text/richText/sms/file）
class HistorySyncEvent extends MessageSyncEvent {
  final History history;

  const HistorySyncEvent({
    required super.sender,
    required super.method,
    required super.opId,
    required super.time,
    required super.source,
    required this.history,
  });
}

/// 图片历史记录同步，载荷含内嵌文件字节, history 对象 content 已置空
class HistoryImageSyncEvent extends HistorySyncEvent {
  final String fileName;

  final Uint8List data;

  const HistoryImageSyncEvent({
    required super.sender,
    required super.method,
    required super.opId,
    required super.time,
    required super.source,
    required super.history,
    required this.fileName,
    required this.data,
  });
}

/// 通知类历史记录同步, history 对象 content 已置空
class HistoryNotificationSyncEvent extends HistorySyncEvent {

  final String pkg;

  final String title;

  final String content;

  const HistoryNotificationSyncEvent({
    required super.sender,
    required super.method,
    required super.opId,
    required super.time,
    required super.source,
    required super.history,
    required this.pkg,
    required this.title,
    required this.content,
  });
}

/// 历史记录置顶状态同步
class HistoryTopSyncEvent extends MessageSyncEvent {
  final int historyId;

  final bool top;

  const HistoryTopSyncEvent({
    required super.sender,
    required super.method,
    required super.opId,
    required super.time,
    required super.source,
    required this.historyId,
    required this.top,
  });
}

/// 历史记录来源同步，sourceAppId 为 null 表示清除来源
class HistorySourceSyncEvent extends MessageSyncEvent {
  final int historyId;

  final String? sourceAppId;

  const HistorySourceSyncEvent({
    required super.sender,
    required super.method,
    required super.opId,
    required super.time,
    required super.source,
    required this.historyId,
    required this.sourceAppId,
  });
}

/// 标签增删同步
class HistoryTagSyncEvent extends MessageSyncEvent {
  final HistoryTag tag;

  const HistoryTagSyncEvent({
    required super.sender,
    required super.method,
    required super.opId,
    required super.time,
    required super.source,
    required this.tag,
  });
}

/// App 来源信息同步
class AppInfoSyncEvent extends MessageSyncEvent {
  final AppInfo appInfo;

  const AppInfoSyncEvent({
    required super.sender,
    required super.method,
    required super.opId,
    required super.time,
    required super.source,
    required this.appInfo,
  });
}

/// 规则同步
class RuleSyncEvent extends MessageSyncEvent {
  final Rule rule;

  const RuleSyncEvent({
    required super.sender,
    required super.method,
    required super.opId,
    required super.time,
    required super.source,
    required this.rule,
  });
}

/// 脚本模块同步
class ScriptModuleSyncEvent extends MessageSyncEvent {
  final ScriptModule scriptModule;

  const ScriptModuleSyncEvent({
    required super.sender,
    required super.method,
    required super.opId,
    required super.time,
    required super.source,
    required this.scriptModule,
  });
}

/// 设备模块 ack
class DeviceAckSyncEvent extends MessageAckSyncEvent {
  const DeviceAckSyncEvent({required super.sender, required super.opId});
}

/// 历史记录模块 ack（图片、通知载荷同属 history 模块）
class HistoryAckSyncEvent extends MessageAckSyncEvent {
  const HistoryAckSyncEvent({required super.sender, required super.opId});
}

/// 历史记录置顶模块 ack
class HistoryTopAckSyncEvent extends MessageAckSyncEvent {
  const HistoryTopAckSyncEvent({required super.sender, required super.opId});
}

/// 历史记录来源模块 ack
class HistorySourceAckSyncEvent extends MessageAckSyncEvent {
  const HistorySourceAckSyncEvent({required super.sender, required super.opId});
}

/// 标签模块 ack
class HistoryTagAckSyncEvent extends MessageAckSyncEvent {
  const HistoryTagAckSyncEvent({required super.sender, required super.opId});
}

/// App 来源信息模块 ack
class AppInfoAckSyncEvent extends MessageAckSyncEvent {
  const AppInfoAckSyncEvent({required super.sender, required super.opId});
}

/// 规则模块 ack
class RuleAckSyncEvent extends MessageAckSyncEvent {
  const RuleAckSyncEvent({required super.sender, required super.opId});
}

/// 脚本模块模块 ack
class ScriptModuleAckSyncEvent extends MessageAckSyncEvent {
  const ScriptModuleAckSyncEvent({required super.sender, required super.opId});
}
