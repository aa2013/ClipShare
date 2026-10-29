import 'dart:convert';
import 'dart:typed_data';

import 'package:clipshare/core/database/app_database.dart';
import 'package:clipshare/core/services/transport/message_sync/message_sync_event.dart';
import 'package:clipshare/shared/enums/history_content_type.dart';

import 'sync_payload_context.dart';

/// 解析历史记录同步载荷，通知正文统一提取为事件字段并保留入库内容。
MessageSyncEvent? parseHistorySyncPayload(SyncPayloadContext context) {
  final raw = context.data;
  if (raw.isEmpty) {
    return null;
  }
  final payload = Map<String, dynamic>.from(raw);
  final content = payload['content'];
  final type = HistoryContentType.parse(payload['type'] ?? '');
  if (type == .notification && context.method != .delete) {
    final dynamic notification;
    try {
      notification = content is String ? jsonDecode(content) : content;
    } on FormatException {
      return null;
    }
    if (notification is! Map) {
      return null;
    }
    final pkg = notification['pkg'];
    final title = notification['title'];
    final body = notification['content'];
    if ((pkg != null && pkg is! String) ||
        (title != null && title is! String) ||
        (body != null && body is! String)) {
      return null;
    }
    payload['content'] = content is String ? content : jsonEncode(notification);
    return HistoryNotificationSyncEvent(
      sender: context.sender,
      method: context.method,
      opId: context.opId,
      time: context.time,
      source: context.source,
      history: History.fromJson(payload),
      pkg: pkg,
      title: title,
      content: body,
    );
  }
  // 通知删除仅依赖记录标识，不解析已被清理的正文。
  if (type == .notification && context.method == .delete) {
    payload['content'] = '';
  } else if (content is Map) {
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
