import 'package:clipshare/core/database/app_database.dart' show AppDriftValueSerializer;
import 'package:clipshare/core/database/tables/script_module.dart';
import 'package:clipshare/core/services/device/local_device_info.dart';
import 'package:clipshare/core/services/transport/message_sync/message_sync_event.dart';
import 'package:clipshare/core/services/transport/message_sync/parser/script_module_sync_payload_parser.dart';
import 'package:clipshare/core/services/transport/message_sync/parser/sync_payload_context.dart';
import 'package:clipshare/shared/enums/rule/rule_script_language.dart';
import 'package:clipshare/shared/enums/sync_source.dart';
import 'package:clipshare/shared/extensions/platform_extension.dart';
import 'package:clipshare/shared/models/op_method.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';

final _sender = BaseDeviceInfo(
  guid: 'sender-guid',
  name: 'sender',
  type: PlatformType.windows,
);

const _time = '2026-01-01 00:00:00';
const _opId = 99;

/// 构造脚本模块同步载荷底稿。
ScriptModule _module() {
  return const ScriptModule(
    moduleName: 'utils',
    displayName: 'Utils',
    language: RuleScriptLanguage.lua,
    source: 'return {}',
    version: 100,
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
  setUpAll(() {
    // 同步载荷使用数据库统一的枚举序列化规则
    driftRuntimeOptions.defaultSerializer = const AppDriftValueSerializer();
  });

  group('parseScriptModuleSyncPayload', () {
    test('returns null for empty data', () {
      expect(parseScriptModuleSyncPayload(_context(<String, dynamic>{})), isNull);
    });

    test('returns null for invalid module name or version types', () {
      expect(
        parseScriptModuleSyncPayload(
          _context(<String, dynamic>{'moduleName': '', 'version': 1}),
        ),
        isNull,
      );
      expect(
        parseScriptModuleSyncPayload(
          _context(<String, dynamic>{'moduleName': 'utils', 'version': '1'}),
        ),
        isNull,
      );
    });

    test('parses script module payload and forwards context meta', () {
      final module = _module();

      final event = parseScriptModuleSyncPayload(
        _context(scriptModuleToSyncPayload(module)),
      );

      expect(event, isA<ScriptModuleSyncEvent>());
      final moduleEvent = event! as ScriptModuleSyncEvent;
      _expectContextMeta(moduleEvent);
      expect(moduleEvent.scriptModule.moduleName, module.moduleName);
      expect(moduleEvent.scriptModule.displayName, module.displayName);
      expect(moduleEvent.scriptModule.version, module.version);
      expect(moduleEvent.scriptModule.isNewData, isFalse);
    });

    test('restores isNewData from payload', () {
      final payload = scriptModuleToSyncPayload(_module())
        ..['isNewData'] = true;

      final event = parseScriptModuleSyncPayload(_context(payload));

      expect(event, isA<ScriptModuleSyncEvent>());
      expect((event! as ScriptModuleSyncEvent).scriptModule.isNewData, isTrue);
    });

    test('returns null when language is missing', () {
      final payload = scriptModuleToSyncPayload(_module())..remove('language');

      expect(parseScriptModuleSyncPayload(_context(payload)), isNull);
    });

    test('forwards sync source to event', () {
      final event = parseScriptModuleSyncPayload(
        _context(scriptModuleToSyncPayload(_module()), source: SyncSource.storage),
      );

      expect(event, isA<ScriptModuleSyncEvent>());
      _expectContextMeta(event! as ScriptModuleSyncEvent, source: SyncSource.storage);
    });
  });
}
