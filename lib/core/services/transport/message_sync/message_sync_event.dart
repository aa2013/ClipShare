import 'dart:typed_data';

import 'package:clipshare/core/database/app_database.dart';
import 'package:clipshare/core/services/device/local_device_info.dart';
import 'package:clipshare/shared/enums/sync_source.dart';
import 'package:clipshare/shared/models/module.dart';
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

  /// 事件所属同步模块
  Module get module;

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

  /// 确认事件所属同步模块
  Module get module;

  const MessageAckSyncEvent({required this.sender, required this.opId});
}

/// 设备元数据同步
class DeviceSyncEvent extends MessageSyncEvent {
  final Device device;

  @override
  Module get module => Module.device;

  const DeviceSyncEvent({
    required super.sender,
    required super.method,
    required super.opId,
    required super.time,
    required super.source,
    required this.device,
  });
}

/// 历史记录同步（text/sms/file）
class HistorySyncEvent extends MessageSyncEvent {
  final History history;

  @override
  Module get module => Module.history;

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

/// 通知类历史记录同步，字段用于展示，history.content 保留完整 JSON 正文用于入库。
class HistoryNotificationSyncEvent extends HistorySyncEvent {

  final String? pkg;

  final String? title;

  final String? content;

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

  @override
  Module get module => Module.historyTop;

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

  @override
  Module get module => Module.historySource;

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

  @override
  Module get module => Module.tag;

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

  @override
  Module get module => Module.appInfo;

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

  @override
  Module get module => Module.rule;

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

  @override
  Module get module => Module.scriptModule;

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
  @override
  Module get module => Module.device;

  const DeviceAckSyncEvent({required super.sender, required super.opId});
}

/// 历史记录模块 ack（图片、通知载荷同属 history 模块）
class HistoryAckSyncEvent extends MessageAckSyncEvent {
  @override
  Module get module => Module.history;

  const HistoryAckSyncEvent({required super.sender, required super.opId});
}

/// 历史记录置顶模块 ack
class HistoryTopAckSyncEvent extends MessageAckSyncEvent {
  @override
  Module get module => Module.historyTop;

  const HistoryTopAckSyncEvent({required super.sender, required super.opId});
}

/// 历史记录来源模块 ack
class HistorySourceAckSyncEvent extends MessageAckSyncEvent {
  @override
  Module get module => Module.historySource;

  const HistorySourceAckSyncEvent({required super.sender, required super.opId});
}

/// 标签模块 ack
class HistoryTagAckSyncEvent extends MessageAckSyncEvent {
  @override
  Module get module => Module.tag;

  const HistoryTagAckSyncEvent({required super.sender, required super.opId});
}

/// App 来源信息模块 ack
class AppInfoAckSyncEvent extends MessageAckSyncEvent {
  @override
  Module get module => Module.appInfo;

  const AppInfoAckSyncEvent({required super.sender, required super.opId});
}

/// 规则模块 ack
class RuleAckSyncEvent extends MessageAckSyncEvent {
  @override
  Module get module => Module.rule;

  const RuleAckSyncEvent({required super.sender, required super.opId});
}

/// 脚本模块模块 ack
class ScriptModuleAckSyncEvent extends MessageAckSyncEvent {
  @override
  Module get module => Module.scriptModule;

  const ScriptModuleAckSyncEvent({required super.sender, required super.opId});
}

/// 按模块构造对应的确认事件。
///
/// `unknown` 与已废弃的 `rules` 模块不参与当前同步协议，返回 null。
MessageAckSyncEvent? ackEventOfModule(
  Module module, {
  required BaseDeviceInfo sender,
  required int opId,
}) => switch (module) {
  Module.device => DeviceAckSyncEvent(sender: sender, opId: opId),
  Module.history => HistoryAckSyncEvent(sender: sender, opId: opId),
  Module.historyTop => HistoryTopAckSyncEvent(sender: sender, opId: opId),
  Module.historySource => HistorySourceAckSyncEvent(sender: sender, opId: opId),
  Module.tag => HistoryTagAckSyncEvent(sender: sender, opId: opId),
  Module.appInfo => AppInfoAckSyncEvent(sender: sender, opId: opId),
  Module.rule => RuleAckSyncEvent(sender: sender, opId: opId),
  Module.scriptModule => ScriptModuleAckSyncEvent(sender: sender, opId: opId),
  Module.unknown || Module.rules => null,
};

/// 根据已应用的同步事件构造待回传的确认事件。
MessageAckSyncEvent? ackEventFor(MessageSyncEvent event) {
  return ackEventOfModule(
    event.module,
    sender: event.sender,
    opId: event.opId,
  );
}

///缺失数据批量补数的进度事件
class MissingDataBatchEvent {
  ///发送方设备 id
  final String devId;

  ///批次内序号（从 1 开始）
  final int seq;

  ///批次总数
  final int total;

  const MissingDataBatchEvent({
    required this.devId,
    required this.seq,
    required this.total,
  });
}
