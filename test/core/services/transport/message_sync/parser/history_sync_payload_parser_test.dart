import 'dart:convert';
import 'dart:typed_data';

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

/// 构造合法历史记录，作为同步载荷底稿
History _history({
  HistoryContentType type = HistoryContentType.text,
  String content = 'hello',
}) {
  return History(
    id: 1,
    uid: 2,
    time: _time,
    content: content,
    type: type.value,
    devId: 'dev-1',
    top: false,
    sync: true,
    size: content.length,
  );
}

/// 构造解析上下文，可指定操作与同步来源以验证事件透传。
SyncPayloadContext _context(
  Map<String, dynamic> data, {
  SyncSource source = SyncSource.direct,
  OpMethod method = OpMethod.add,
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
  SyncSource source = SyncSource.direct,
  OpMethod method = OpMethod.add,
}) {
  expect(event.sender, same(_sender));
  expect(event.method, method);
  expect(event.opId, _opId);
  expect(event.time, _time);
  expect(event.source, source);
}

void main() {
  group('parseHistorySyncPayload', () {
    test('returns null for empty data', () {
      expect(parseHistorySyncPayload(_context(<String, dynamic>{})), isNull);
    });

    test('parses text history and forwards context meta', () {
      final history = _history();

      final event = parseHistorySyncPayload(_context(history.toJson()));

      expect(event, isA<HistorySyncEvent>());
      final historyEvent = event! as HistorySyncEvent;
      _expectContextMeta(historyEvent);
      expect(historyEvent.history.id, history.id);
      expect(historyEvent.history.type, HistoryContentType.text.value);
      expect(historyEvent.history.content, history.content);
    });

    test('parses image payload and clears history content', () {
      final history = _history(type: HistoryContentType.image, content: '');
      final payload = history.toJson()
        ..['content'] = <String, dynamic>{
          'fileName': 'a.png',
          'data': <int>[1, 2, 255],
        };

      final event = parseHistorySyncPayload(_context(payload));

      expect(event, isA<HistoryImageSyncEvent>());
      final imageEvent = event! as HistoryImageSyncEvent;
      _expectContextMeta(imageEvent);
      expect(imageEvent.fileName, 'a.png');
      expect(imageEvent.data, Uint8List.fromList(<int>[1, 2, 255]));
      expect(imageEvent.history.id, history.id);
      expect(imageEvent.history.type, HistoryContentType.image.value);
      expect(imageEvent.history.content, isEmpty);
    });

    test('returns null when image fileName is missing or empty', () {
      final missingFileName = _history(type: HistoryContentType.image, content: '').toJson()
        ..['content'] = <String, dynamic>{
          'data': <int>[1],
        };
      final emptyFileName = _history(type: HistoryContentType.image, content: '').toJson()
        ..['content'] = <String, dynamic>{
          'fileName': '',
          'data': <int>[1],
        };

      expect(parseHistorySyncPayload(_context(missingFileName)), isNull);
      expect(parseHistorySyncPayload(_context(emptyFileName)), isNull);
    });

    test('returns null when image data is not a list', () {
      final payload = _history(type: HistoryContentType.image, content: '').toJson()
        ..['content'] = <String, dynamic>{
          'fileName': 'a.png',
          'data': 'not-a-list',
        };

      expect(parseHistorySyncPayload(_context(payload)), isNull);
    });

    test('returns null for map content with unsupported type', () {
      final textPayload = _history().toJson()..['content'] = <String, dynamic>{'foo': 'bar'};
      final unknownTypePayload = _history().toJson()
        ..remove('type')
        ..['content'] = <String, dynamic>{'foo': 'bar'};

      expect(parseHistorySyncPayload(_context(textPayload)), isNull);
      expect(parseHistorySyncPayload(_context(unknownTypePayload)), isNull);
    });

    test('parses notification map and preserves complete history content', () {
      final history = _history(
        type: HistoryContentType.notification,
        content: '',
      );
      final payload = history.toJson()
        ..['content'] = <String, dynamic>{
          'pkg': 'com.example.app',
          'title': 'title',
          'content': 'body',
          'extra': 'preserved',
        };

      final event = parseHistorySyncPayload(_context(payload));

      expect(event, isA<HistoryNotificationSyncEvent>());
      final notificationEvent = event! as HistoryNotificationSyncEvent;
      _expectContextMeta(notificationEvent);
      expect(notificationEvent.pkg, 'com.example.app');
      expect(notificationEvent.title, 'title');
      expect(notificationEvent.content, 'body');
      expect(notificationEvent.history.id, history.id);
      expect(
        notificationEvent.history.type,
        HistoryContentType.notification.value,
      );
      expect(jsonDecode(notificationEvent.history.content), payload['content']);
      expect(payload['content'], isA<Map>());
    });

    test('parses notification JSON and forwards update and missing-data metadata', () {
      const content = '{ "pkg": "com.example.app", "title": "标题", "content": "正文", "extra": 1 }';
      final history = _history(type: HistoryContentType.notification, content: content);
      final event = parseHistorySyncPayload(_context(
        history.toJson(),
        method: OpMethod.update,
        source: SyncSource.missingData,
      ));

      expect(event, isA<HistoryNotificationSyncEvent>());
      final notification = event! as HistoryNotificationSyncEvent;
      _expectContextMeta(notification, method: OpMethod.update, source: SyncSource.missingData);
      expect(notification.pkg, 'com.example.app');
      expect(notification.title, '标题');
      expect(notification.content, '正文');
      expect(notification.history.content, content);
    });

    test('rejects malformed and non-object notification content', () {
      for (final content in <Object?>['{invalid', '', '[]', 'null', '1', '"text"', null, 1, <Object>[]]) {
        final payload = _history(type: HistoryContentType.notification).toJson()..['content'] = content;
        expect(parseHistorySyncPayload(_context(payload)), isNull, reason: '$content');
      }
    });

    test('rejects incorrect notification field types in maps and JSON', () {
      for (final field in ['pkg', 'title', 'content']) {
        final body = <String, dynamic>{field: 1};
        for (final content in <Object>[body, jsonEncode(body)]) {
          final payload = _history(type: HistoryContentType.notification).toJson()..['content'] = content;
          expect(parseHistorySyncPayload(_context(payload)), isNull, reason: '$content');
        }
      }
    });

    test('parses notification deletion without requiring valid content', () {
      for (final content in <Object?>['', '{invalid', null, <String, dynamic>{'title': 1}]) {
        final payload = _history(type: HistoryContentType.notification).toJson()..['content'] = content;
        final event = parseHistorySyncPayload(_context(payload, method: OpMethod.delete));

        expect(event, isA<HistorySyncEvent>());
        expect(event, isNot(isA<HistoryNotificationSyncEvent>()));
        final historyEvent = event! as HistorySyncEvent;
        _expectContextMeta(historyEvent, method: OpMethod.delete);
        expect(historyEvent.history.id, payload['id']);
      }
    });

    test('parses notification without optional fields', () {
      for (final content in <Object>[<String, dynamic>{}, '{}', '{"pkg":null,"title":null,"content":null}']) {
        final payload = _history(type: HistoryContentType.notification).toJson()..['content'] = content;
        final event = parseHistorySyncPayload(_context(payload));

        final notificationEvent = event! as HistoryNotificationSyncEvent;
        expect(notificationEvent.pkg, isNull);
        expect(notificationEvent.title, isNull);
        expect(notificationEvent.content, isNull);
        expect(jsonDecode(notificationEvent.history.content), isA<Map>());
      }
    });

    test('matches content type case-insensitively', () {
      final payload = _history(type: HistoryContentType.image, content: '').toJson()
        ..['type'] = HistoryContentType.image.value.toLowerCase()
        ..['content'] = <String, dynamic>{
          'fileName': 'a.png',
          'data': <int>[1],
        };

      expect(
        parseHistorySyncPayload(_context(payload)),
        isA<HistoryImageSyncEvent>(),
      );
    });

    test('does not mutate the input payload', () {
      final payload = _history(type: HistoryContentType.image, content: '').toJson()
        ..['content'] = <String, dynamic>{
          'fileName': 'a.png',
          'data': <int>[1],
        };

      parseHistorySyncPayload(_context(payload));

      final content = payload['content'] as Map<String, dynamic>;
      expect(content['fileName'], 'a.png');
      expect(content['data'], <int>[1]);
    });

    test('forwards sync source to event', () {
      final event = parseHistorySyncPayload(
        _context(_history().toJson(), source: SyncSource.storage),
      );

      expect(event, isA<HistorySyncEvent>());
      final historyEvent = event! as HistorySyncEvent;
      _expectContextMeta(historyEvent, source: SyncSource.storage);
      expect(historyEvent.storageSync, isTrue);
    });
  });
  group('parseHistoryTopSyncPayload', () {
    test('returns null for incorrect top type', () {
      expect(
        parseHistoryTopSyncPayload(
          _context(<String, dynamic>{
            'top': 1,
            'id': 1,
          }),
        ),
        isNull,
      );
    });
    test('returns null for incorrect id type', () {
      expect(
        parseHistoryTopSyncPayload(
          _context(<String, dynamic>{
            'top': true,
            'id': '1',
          }),
        ),
        isNull,
      );
    });
    test('returns event for normal data', () {
      final event = parseHistoryTopSyncPayload(
        _context(<String, dynamic>{
          'top': true,
          'id': 1,
        }),
      );
      expect(event, isNotNull);
      final historyTopEvent = event as HistoryTopSyncEvent;
      expect(historyTopEvent.top, isTrue);
      expect(historyTopEvent.historyId, 1);
    });
  });
}
