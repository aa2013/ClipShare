import 'package:clipshare/core/services/device/local_device_info.dart';
import 'package:clipshare/shared/enums/sync_source.dart';
import 'package:clipshare/shared/models/op_method.dart';

import '../message_sync_event.dart';

/// 模块载荷解析函数。
///
/// 返回 null 表示载荷无法识别，分发层会跳过该消息且不发送确认
typedef SyncPayloadParser = MessageSyncEvent? Function(SyncPayloadContext context);

/// 单条同步载荷的解析上下文，操作元信息由分发层统一读取后传入。
class SyncPayloadContext {
  /// 发送该操作的设备
  final BaseDeviceInfo sender;

  /// 操作类型
  final OpMethod method;

  /// 发送端操作记录 id
  final int opId;

  /// 操作发生时间
  final String time;

  /// 同步来源
  final SyncSource source;

  /// 操作记录中的实体载荷（payload['data']）
  final Map<String, dynamic> data;

  const SyncPayloadContext({
    required this.sender,
    required this.method,
    required this.opId,
    required this.time,
    required this.source,
    required this.data,
  });
}
