import 'dart:typed_data';

import 'package:clipshare/core/database/app_database.dart';
import 'package:clipshare/core/services/transport/message_sync/message_sync_event.dart';
import 'package:clipshare/shared/enums/history_content_type.dart';

import 'sync_payload_context.dart';

/// 解析历史记录同步载荷。
MessageSyncEvent? parseHistorySyncPayload(SyncPayloadContext context) {
  final raw = context.data;
  if (raw.isEmpty) {
    return null;
  }
  final payload = Map<String, dynamic>.from(raw);
  final content = payload['content'];
  if (content is Map) {
    final type = HistoryContentType.parse(payload['type'] ?? '');
    if (type == .image) {
      final fileName = content['fileName']?.toString() ?? '';
      final bytes = content['data'];
      if (fileName.isEmpty || bytes is! List) {
        return null;
      }
      // 清除content字段
      payload['content'] = '';
      return HistoryImageSyncEvent(
        sender: context.sender,
        method: context.method,
        opId: context.opId,
        time: context.time,
        source: context.source,
        history: History.fromJson(payload),
        fileName: fileName,
        data: Uint8List.fromList(bytes.cast<int>()),
      );
    }
    if (type == .notification) {
      // 清除content字段
      payload['content'] = '';
      return HistoryNotificationSyncEvent(
        sender: context.sender,
        method: context.method,
        opId: context.opId,
        time: context.time,
        source: context.source,
        history: History.fromJson(payload),
        pkg: content['pkg'],
        title: content['title'],
        content: content['content'],
      );
    }
    return null;
  }
  return HistorySyncEvent(
    sender: context.sender,
    method: context.method,
    opId: context.opId,
    time: context.time,
    source: context.source,
    history: History.fromJson(payload),
  );
}

/// 解析历史记录来源同步载荷。
MessageSyncEvent? parseHistorySourceSyncPayload(SyncPayloadContext context) {
  final payload = context.data;
  if (payload.isEmpty) {
    return null;
  }
  final id = payload['id'];
  final source = payload['source'];
  if (id is! int || (source != null && source is! String)) {
    return null;
  }
  return HistorySourceSyncEvent(
    sender: context.sender,
    method: context.method,
    opId: context.opId,
    time: context.time,
    source: context.source,
    historyId: id,
    sourceAppId: source as String?,
  );
}

/// 解析历史记录置顶/取消置顶同步载荷
MessageSyncEvent? parseHistoryTopSyncPayload(SyncPayloadContext context) {
  final raw = context.data;
  if (raw.isEmpty) {
    return null;
  }
  final payload = Map<String, dynamic>.from(raw);
  final isTop = payload['top'];
  if (isTop is! bool) {
    return null;
  }
  final id = payload['id'];
  if (id is! int) {
    return null;
  }
  return HistoryTopSyncEvent(
    sender: context.sender,
    method: context.method,
    opId: context.opId,
    time: context.time,
    source: context.source,
    historyId: id,
    top: isTop,
  );
}
