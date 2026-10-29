import 'package:clipshare/core/database/tables/rule.dart';
import 'package:clipshare/core/services/device/local_device_info.dart';
import 'package:clipshare/core/services/transport/message_sync/message_sync_event.dart';
import 'package:clipshare/core/services/transport/message_sync/parser/rule_sync_payload_parser.dart';
import 'package:clipshare/core/services/transport/message_sync/parser/sync_payload_context.dart';
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

/// 构造规则同步载荷底稿。
Rule _rule() {
  return emptyRule().copyWith(
    id: 1,
    name: 'rule',
    version: 100,
    order: 1,
  );
}

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
  group('parseRuleSyncPayload', () {
    test('returns null for empty data', () {
      expect(parseRuleSyncPayload(_context(<String, dynamic>{})), isNull);
    });

    test('returns null for invalid id or version types', () {
      expect(
        parseRuleSyncPayload(
          _context(<String, dynamic>{'id': '1', 'version': 1}),
        ),
        isNull,
      );
      expect(
        parseRuleSyncPayload(
          _context(<String, dynamic>{'id': 1, 'version': '1'}),
        ),
        isNull,
      );
    });

    test('parses rule payload and forwards context meta', () {
      final rule = _rule();

      final event = parseRuleSyncPayload(_context(ruleToSyncPayload(rule)));

      expect(event, isA<RuleSyncEvent>());
      final ruleEvent = event! as RuleSyncEvent;
      _expectContextMeta(ruleEvent);
      expect(ruleEvent.rule.id, rule.id);
      expect(ruleEvent.rule.name, rule.name);
      expect(ruleEvent.rule.version, rule.version);
    });

    test('accepts legacy language and content fields', () {
      final payload = ruleToSyncPayload(_rule());
      expect(payload.containsKey('language'), isTrue);
      expect(payload.containsKey('content'), isTrue);
      expect(payload.containsKey('scriptLanguage'), isFalse);
      expect(payload.containsKey('scriptContent'), isFalse);

      final event = parseRuleSyncPayload(_context(payload));

      expect(event, isA<RuleSyncEvent>());
      final ruleEvent = event! as RuleSyncEvent;
      expect(ruleEvent.rule.scriptLanguage, 'lua');
      expect(ruleEvent.rule.scriptContent, '');
    });

    test('returns null when required fields are missing', () {
      final payload = ruleToSyncPayload(_rule())..remove('platforms');

      expect(parseRuleSyncPayload(_context(payload)), isNull);
    });

    test('forwards sync source to event', () {
      final event = parseRuleSyncPayload(
        _context(ruleToSyncPayload(_rule()), source: SyncSource.storage),
      );

      expect(event, isA<RuleSyncEvent>());
      _expectContextMeta(event! as RuleSyncEvent, source: SyncSource.storage);
    });
  });
}
