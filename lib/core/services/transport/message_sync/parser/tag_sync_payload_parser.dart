import 'package:clipshare/core/database/tables/history_tag.dart';
import 'package:clipshare/core/services/transport/message_sync/message_sync_event.dart';

import 'sync_payload_context.dart';

/// 解析标签同步载荷。
MessageSyncEvent? parseTagSyncPayload(SyncPayloadContext context) {
  final payload = context.data;
  final id = payload['id'];
  final tagName = payload['tagName'];
  final hisId = payload['hisId'];
  if (id is! int || tagName is! String || hisId is! int) {
    return null;
  }
  return HistoryTagSyncEvent(
    sender: context.sender,
    method: context.method,
    opId: context.opId,
    time: context.time,
    source: context.source,
    tag: HistoryTag(
      id: id,
      tagName: tagName,
      hisId: hisId,
    ),
  );
}
