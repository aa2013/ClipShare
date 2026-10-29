import 'package:clipshare/core/database/app_database.dart';
import 'package:clipshare/core/services/device/local_device_info.dart';
import 'package:clipshare/core/services/transport/message_sync/message_sync_event.dart';
import 'package:clipshare/core/services/transport/message_sync/parser/history_sync_payload_parser.dart';
import 'package:clipshare/core/services/transport/message_sync/parser/sync_payload_context.dart';
import 'package:clipshare/shared/enums/history_content_type.dart';
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

/// 构造历史记录同步载荷底稿。
History _history({String? source}) {
  return History(
    id: 1,
    uid: 2,
    time: _time,
    content: '',
    type: HistoryContentType.text.value,
    devId: 'dev-1',
    top: false,
    sync: true,
    size: 0,
    source: source,
  );
}

/// 构造解析上下文，操作元信息固定以便断言透传。
SyncPayloadContext _context(
  Map<String, dynamic> data, {
  OpMethod method = OpMethod.update,
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
  OpMethod method = OpMethod.update,
  SyncSource source = SyncSource.direct,
}) {
  expect(event.sender, same(_sender));
  expect(event.method, method);
  expect(event.opId, _opId);
  expect(event.time, _time);
  expect(event.source, source);
}

void main() {
  group('parseHistorySourceSyncPayload', () {
    test('returns null for empty data', () {
      expect(parseHistorySourceSyncPayload(_context(<String, dynamic>{})), isNull);
    });

    test('returns null for invalid id or source types', () {
      expect(
        parseHistorySourceSyncPayload(
          _context(<String, dynamic>{'id': '1', 'source': 'app'}),
        ),
        isNull,
      );
      expect(
        parseHistorySourceSyncPayload(
          _context(<String, dynamic>{'id': 1, 'source': 1}),
        ),
        isNull,
      );
    });

    test('parses history source update payload', () {
      final history = _history(source: 'com.example.app');

      final event = parseHistorySourceSyncPayload(_context(history.toJson()));

      expect(event, isA<HistorySourceSyncEvent>());
      final sourceEvent = event! as HistorySourceSyncEvent;
      _expectContextMeta(sourceEvent);
      expect(sourceEvent.historyId, history.id);
      expect(sourceEvent.sourceAppId, 'com.example.app');
    });

    test('parses payload without source as cleared source', () {
      final history = _history();

      final event = parseHistorySourceSyncPayload(
        _context(history.toJson(), method: OpMethod.delete),
      );

      expect(event, isA<HistorySourceSyncEvent>());
      final sourceEvent = event! as HistorySourceSyncEvent;
      _expectContextMeta(sourceEvent, method: OpMethod.delete);
      expect(sourceEvent.historyId, history.id);
      expect(sourceEvent.sourceAppId, isNull);
    });

    test('forwards sync source to event', () {
      final event = parseHistorySourceSyncPayload(
        _context(_history(source: 'com.example.app').toJson(), source: SyncSource.storage),
      );

      expect(event, isA<HistorySourceSyncEvent>());
      _expectContextMeta(event! as HistorySourceSyncEvent, source: SyncSource.storage);
    });
  });
}
