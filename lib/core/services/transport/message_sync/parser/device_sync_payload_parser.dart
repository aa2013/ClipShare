import 'package:clipshare/core/database/tables/device.dart';
import 'package:clipshare/core/services/transport/message_sync/message_sync_event.dart';

import 'sync_payload_context.dart';

/// 解析设备元数据同步载荷。
MessageSyncEvent? parseDeviceSyncPayload(SyncPayloadContext context) {
  final payload = context.data;
  final guid = payload['guid'];
  if (guid is! String || guid.isEmpty) {
    return null;
  }
  try {
    return DeviceSyncEvent(
      sender: context.sender,
      method: context.method,
      opId: context.opId,
      time: context.time,
      source: context.source,
      device: Device.fromJson(payload),
    );
  } catch (_) {
    return null;
  }
}
