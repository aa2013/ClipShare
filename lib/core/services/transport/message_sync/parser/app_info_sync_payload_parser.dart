import 'package:clipshare/core/database/tables/app_info.dart';
import 'package:clipshare/core/services/transport/message_sync/message_sync_event.dart';

import 'sync_payload_context.dart';

/// 解析 App 来源信息同步载荷。
MessageSyncEvent? parseAppInfoSyncPayload(SyncPayloadContext context) {
  final payload = context.data;
  final id = payload['id'];
  final appId = payload['appId'];
  final devId = payload['devId'];
  final name = payload['name'];
  final iconB64 = payload['iconB64'];
  if (id is! int || appId is! String || devId is! String || name is! String || iconB64 is! String) {
    return null;
  }
  if (appId.isEmpty || devId.isEmpty) {
    return null;
  }
  return AppInfoSyncEvent(
    sender: context.sender,
    method: context.method,
    opId: context.opId,
    time: context.time,
    source: context.source,
    appInfo: AppInfo(
      id: id,
      appId: appId,
      devId: devId,
      name: name,
      iconB64: iconB64,
    ),
  );
}
