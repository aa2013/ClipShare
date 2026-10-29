import 'dart:convert';

import 'package:clipshare/core/services/transport/message_sync/message_sync_event.dart';
import 'package:clipshare/core/services/transport/message_sync/message_sync_provider.dart';
import 'package:clipshare/core/services/transport/message_sync/parser/app_info_sync_payload_parser.dart';
import 'package:clipshare/core/services/transport/message_sync/parser/device_sync_payload_parser.dart';
import 'package:clipshare/core/services/transport/message_sync/parser/history_sync_payload_parser.dart';
import 'package:clipshare/core/services/transport/message_sync/parser/rule_sync_payload_parser.dart';
import 'package:clipshare/core/services/transport/message_sync/parser/script_module_sync_payload_parser.dart';
import 'package:clipshare/core/services/transport/message_sync/parser/tag_sync_payload_parser.dart';
import 'package:clipshare/core/services/transport/models/message_data.dart';
import 'package:clipshare/shared/enums/sync_source.dart';
import 'package:clipshare/shared/models/module.dart';
import 'package:clipshare/shared/models/op_method.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'parser/sync_payload_context.dart';

part 'sync_receive_dispatcher_provider.g.dart';

/// 把同步实体载荷统一转换为 Map。
Map<String, dynamic> normalizeSyncEntityData(
  Object? rawData, {
  required Module module,
  required int opId,
}) {
  if (rawData is Map) {
    return rawData.cast<String, dynamic>();
  }
  if (rawData is String && rawData.isNotEmpty) {
    try {
      final decoded = jsonDecode(rawData);
      if (decoded is Map) {
        return decoded.cast<String, dynamic>();
      }
      logger.warn(
        SyncReceiveDispatcher.tag,
        'sync data is not a json object. module=${module.name}, opId=$opId',
      );
    } catch (err) {
      logger.warn(
        SyncReceiveDispatcher.tag,
        'sync data json decode failed. module=${module.name}, opId=$opId, err=$err',
      );
    }
  }
  return const <String, dynamic>{};
}

/// 同步消息接收分发层
///
/// 负责把载荷解析为强类型事件并投递到事件流
@Riverpod(keepAlive: true)
class SyncReceiveDispatcher extends _$SyncReceiveDispatcher {
  static const tag = 'SyncReceiveDispatcher';

  /// 模块 -> 载荷解析器；未注册的模块视为尚未接入同步接收。
  final Map<Module, SyncPayloadParser> _parsers = {};

  MessageSyncNotifier get _syncNotifier => ref.read(messageSyncProvider.notifier);

  @override
  void build() {
    _parsers[.device] = parseDeviceSyncPayload;
    _parsers[.history] = parseHistorySyncPayload;
    _parsers[.historyTop] = parseHistoryTopSyncPayload;
    _parsers[.historySource] = parseHistorySourceSyncPayload;
    _parsers[.tag] = parseTagSyncPayload;
    _parsers[.appInfo] = parseAppInfoSyncPayload;
    _parsers[.rule] = parseRuleSyncPayload;
    _parsers[.scriptModule] = parseScriptModuleSyncPayload;
  }

  /// 解析 sync / missingData 载荷并投递事件。
  ///
  /// 载荷无法识别时不投递、不确认
  void handleSync(MessageData msg, {required SyncSource source}) {
    final payload = msg.data;
    final sender = msg.send;
    final device = '${sender.name}(${sender.guid})';
    final module = Module.getValue(payload['module']?.toString() ?? '');
    final opId = _readOpId(payload);
    if (module == .unknown || opId == null) {
      logger.warn(
        tag,
        'skip unrecognizable sync message. sender=$device, key=${msg.key.name}, module=${payload['module']}, opId=$opId',
      );
      return;
    }
    final parser = _parsers[module];
    if (parser == null) {
      logger.warn(tag, 'skip sync message because module parser is not registered. module=${module.name}');
      return;
    }
    final rawData = payload['data'];
    final event = parser(
      SyncPayloadContext(
        sender: sender,
        method: OpMethod.getValue(payload['method']?.toString() ?? ''),
        opId: opId,
        time: payload['time']?.toString() ?? '',
        source: source,
        data: normalizeSyncEntityData(rawData, module: module, opId: opId),
      ),
    );
    if (event == null) {
      logger.warn(tag, 'skip sync message because payload parse failed. module=${module.name}, opId=$opId');
      return;
    }
    _syncNotifier.emitSync(event);
  }

  /// 解析对端回传的 ack 消息并投递确认事件。
  void handleAckSync(MessageData msg) {
    final opId = _readOpId(msg.data);
    final sender = msg.send;
    final module = Module.getValue(msg.data['module']?.toString() ?? '');
    final device = '${sender.name}(${sender.guid})';
    if (opId == null || module == .unknown) {
      logger.warn(tag, 'skip unrecognizable ack message. device=$device, module=${msg.data['module']}, opId=$opId');
      return;
    }
    final event = ackEventOfModule(module, sender: sender, opId: opId);
    if (event == null) {
      logger.debug(tag, 'skip ack message for unsupported module. module=${module.name}');
      return;
    }
    _syncNotifier.emitAckSync(event);
  }

  /// 读取操作记录 id
  int? _readOpId(Map<String, dynamic> payload) {
    final id = payload['id'];
    if (id is int) {
      return id;
    }
    if (id is String) {
      return int.tryParse(id);
    }
    return null;
  }
}
