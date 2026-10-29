import 'package:clipshare/core/database/tables/script_module.dart';
import 'package:clipshare/core/services/transport/message_sync/message_sync_event.dart';

import 'sync_payload_context.dart';

/// 解析脚本模块同步载荷。
MessageSyncEvent? parseScriptModuleSyncPayload(SyncPayloadContext context) {
  final payload = context.data;
  final moduleName = payload['moduleName'];
  final version = payload['version'];
  if (moduleName is! String || moduleName.isEmpty || version is! int) {
    return null;
  }
  try {
    return ScriptModuleSyncEvent(
      sender: context.sender,
      method: context.method,
      opId: context.opId,
      time: context.time,
      source: context.source,
      scriptModule: scriptModuleFromJson(payload),
    );
  } catch (_) {
    // 字段缺失或类型异常时视为无法识别的载荷
    return null;
  }
}
