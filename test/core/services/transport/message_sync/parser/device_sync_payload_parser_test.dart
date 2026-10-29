import 'package:clipshare/core/database/tables/device.dart';
import 'package:clipshare/core/services/device/local_device_info.dart';
import 'package:clipshare/core/services/transport/message_sync/message_sync_event.dart';
import 'package:clipshare/core/services/transport/message_sync/parser/device_sync_payload_parser.dart';
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

/// 构建设备载荷底稿。
Device _device() {
  return const Device(
    guid: 'dev-1',
    devName: 'PC',
    uid: 1,
    type: 'windows',
    isPaired: true,
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
  group('parseDeviceSyncPayload', () {
    test('returns null for empty data', () {
      expect(parseDeviceSyncPayload(_context(<String, dynamic>{})), isNull);
    });

    test('returns null when guid is missing or invalid', () {
      expect(parseDeviceSyncPayload(_context(<String, dynamic>{})), isNull);
      expect(
        parseDeviceSyncPayload(_context(<String, dynamic>{'guid': 1})),
        isNull,
      );
      expect(
        parseDeviceSyncPayload(_context(<String, dynamic>{'guid': ''})),
        isNull,
      );
    });

    test('parses device payload and forwards context meta', () {
      final device = _device();

      final event = parseDeviceSyncPayload(_context(device.toJson()));

      expect(event, isA<DeviceSyncEvent>());
      final deviceEvent = event! as DeviceSyncEvent;
      _expectContextMeta(deviceEvent);
      expect(deviceEvent.device.guid, device.guid);
      expect(deviceEvent.device.devName, device.devName);
      expect(deviceEvent.device.isPaired, isTrue);
    });

    test('parses delete payload built from empty device', () {
      final payload = emptyDevice(guid: 'dev-1').toJson();

      final event = parseDeviceSyncPayload(
        _context(payload, method: OpMethod.delete),
      );

      expect(event, isA<DeviceSyncEvent>());
      final deviceEvent = event! as DeviceSyncEvent;
      _expectContextMeta(deviceEvent, method: OpMethod.delete);
      expect(deviceEvent.device.guid, 'dev-1');
    });

    test('forwards sync source to event', () {
      final event = parseDeviceSyncPayload(
        _context(_device().toJson(), source: SyncSource.storage),
      );

      expect(event, isA<DeviceSyncEvent>());
      _expectContextMeta(event! as DeviceSyncEvent, source: SyncSource.storage);
    });
  });
}
