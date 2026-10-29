import 'package:clipshare/core/database/tables/rule.dart';
import 'package:clipshare/core/services/transport/message_sync/message_sync_event.dart';

import 'sync_payload_context.dart';

/// 解析规则同步载荷，兼容旧协议中的 language/content 字段名。
MessageSyncEvent? parseRuleSyncPayload(SyncPayloadContext context) {
  final payload = context.data;
  final id = payload['id'];
  final version = payload['version'];
  if (id is! int || version is! int) {
    return null;
  }
  try {
    return RuleSyncEvent(
      sender: context.sender,
      method: context.method,
      opId: context.opId,
      time: context.time,
      source: context.source,
      rule: ruleFromSyncJson(payload),
    );
  } catch (_) {
    return null;
  }
}
