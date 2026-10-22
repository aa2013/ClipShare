import 'package:clipshare/core/database/tables/app_info.dart';
import 'package:clipshare/core/services/device/local_device_info.dart';
import 'package:clipshare/core/services/transport/message_sync/message_sync_event.dart';
import 'package:clipshare/core/services/transport/message_sync/parser/app_info_sync_payload_parser.dart';
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

/// 构造来源同步载荷底稿。
AppInfo _appInfo() {
  return const AppInfo(
    id: 1,
    appId: 'com.example.app',
    devId: 'dev-1',
    name: 'Example',
    iconB64: '',
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
  group('parseAppInfoSyncPayload', () {
    test('returns null for empty data', () {
      expect(parseAppInfoSyncPayload(_context(<String, dynamic>{})), isNull);
    });

    test('returns null for missing or invalid fields', () {
      expect(
        parseAppInfoSyncPayload(
          _context(<String, dynamic>{'id': '1', 'appId': 'app', 'devId': 'dev', 'name': 'name', 'iconB64': ''}),
        ),
        isNull,
      );
      expect(
        parseAppInfoSyncPayload(
          _context(<String, dynamic>{'id': 1, 'appId': '', 'devId': 'dev', 'name': 'name', 'iconB64': ''}),
        ),
        isNull,
      );
      expect(
        parseAppInfoSyncPayload(
          _context(<String, dynamic>{'id': 1, 'appId': 'app', 'devId': '', 'name': 'name', 'iconB64': ''}),
        ),
        isNull,
      );
      expect(
        parseAppInfoSyncPayload(
          _context(<String, dynamic>{'id': 1, 'appId': 'app', 'devId': 'dev', 'name': 1, 'iconB64': ''}),
        ),
        isNull,
      );
    });

    test('parses app info payload and forwards context meta', () {
      final appInfo = _appInfo();

      final event = parseAppInfoSyncPayload(_context(appInfo.toJson()));

      expect(event, isA<AppInfoSyncEvent>());
      final appInfoEvent = event! as AppInfoSyncEvent;
      _expectContextMeta(appInfoEvent);
      expect(appInfoEvent.appInfo.id, appInfo.id);
      expect(appInfoEvent.appInfo.appId, appInfo.appId);
      expect(appInfoEvent.appInfo.devId, appInfo.devId);
      expect(appInfoEvent.appInfo.name, appInfo.name);
    });

    test('parses update payload', () {
      final event = parseAppInfoSyncPayload(
        _context(_appInfo().toJson(), method: OpMethod.update),
      );

      expect(event, isA<AppInfoSyncEvent>());
      _expectContextMeta(event! as AppInfoSyncEvent, method: OpMethod.update);
    });

    test('forwards sync source to event', () {
      final event = parseAppInfoSyncPayload(
        _context(_appInfo().toJson(), source: SyncSource.storage),
      );

      expect(event, isA<AppInfoSyncEvent>());
      _expectContextMeta(event! as AppInfoSyncEvent, source: SyncSource.storage);
    });
  });
}
