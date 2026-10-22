import 'package:clipshare/core/database/tables/history_tag.dart';
import 'package:clipshare/core/services/device/local_device_info.dart';
import 'package:clipshare/core/services/transport/message_sync/message_sync_event.dart';
import 'package:clipshare/core/services/transport/message_sync/parser/sync_payload_context.dart';
import 'package:clipshare/core/services/transport/message_sync/parser/tag_sync_payload_parser.dart';
import 'package:clipshare/shared/enums/sync_source.dart';
import 'package:clipshare/shared/extensions/platform_extension.dart';
import 'package:clipshare/shared/models/op_method.dart';
import 'package:flutter_test/flutter_test.dart';

final _sender = BaseDeviceInfo(
  guid: 'sender-guid',
  name: 'sender',
  type: PlatformType.windows,
);

const _time = '2026-01-01 00:00:00';
const _opId = 99;

/// 构造解析上下文，操作元信息固定以便断言透传。
SyncPayloadContext _context(
  Map<String, dynamic> data, {
  OpMethod method = OpMethod.add,
  SyncSource source = SyncSource.direct,
}) {
  return SyncPayloadContext(
    sender: _sender,
    method: method,
    opId: _opId,
    time: _time,
    source: source,
    data: data,
  );
}

/// 断言事件完整透传上下文中的操作元信息。
void _expectContextMeta(
  MessageSyncEvent event, {
  OpMethod method = OpMethod.add,
  SyncSource source = SyncSource.direct,
}) {
  expect(event.sender, same(_sender));
  expect(event.method, method);
  expect(event.opId, _opId);
  expect(event.time, _time);
  expect(event.source, source);
}

void main() {
  group('parseTagSyncPayload', () {
    test('returns null for empty data', () {
      expect(parseTagSyncPayload(_context(<String, dynamic>{})), isNull);
    });

    test('returns null for invalid field types', () {
      expect(
        parseTagSyncPayload(
          _context(<String, dynamic>{'id': '1', 'tagName': 'tag', 'hisId': 1}),
        ),
        isNull,
      );
      expect(
        parseTagSyncPayload(
          _context(<String, dynamic>{'id': 1, 'tagName': 1, 'hisId': 1}),
        ),
        isNull,
      );
      expect(
        parseTagSyncPayload(
          _context(<String, dynamic>{'id': 1, 'tagName': 'tag', 'hisId': '1'}),
        ),
        isNull,
      );
    });

    test('parses tag payload and forwards context meta', () {
      const tag = HistoryTag(id: 10, tagName: 'work', hisId: 20);

      final event = parseTagSyncPayload(_context(tag.toJson()));

      expect(event, isA<HistoryTagSyncEvent>());
      final tagEvent = event! as HistoryTagSyncEvent;
      _expectContextMeta(tagEvent);
      expect(tagEvent.tag.id, tag.id);
      expect(tagEvent.tag.tagName, tag.tagName);
      expect(tagEvent.tag.hisId, tag.hisId);
    });

    test('parses delete payload with empty tag name', () {
      final tag = emptyHistoryTag(id: 10);

      final event = parseTagSyncPayload(
        _context(tag.toJson(), method: OpMethod.delete),
      );

      expect(event, isA<HistoryTagSyncEvent>());
      final tagEvent = event! as HistoryTagSyncEvent;
      _expectContextMeta(tagEvent, method: OpMethod.delete);
      expect(tagEvent.tag.id, 10);
      expect(tagEvent.tag.tagName, isEmpty);
      expect(tagEvent.tag.hisId, 0);
    });

    test('forwards sync source to event', () {
      const tag = HistoryTag(id: 10, tagName: 'work', hisId: 20);

      final event = parseTagSyncPayload(
        _context(tag.toJson(), source: SyncSource.storage),
      );

      expect(event, isA<HistoryTagSyncEvent>());
      final tagEvent = event! as HistoryTagSyncEvent;
      _expectContextMeta(tagEvent, source: SyncSource.storage);
      expect(tagEvent.storageSync, isTrue);
    });
  });
}
