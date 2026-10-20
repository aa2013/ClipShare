import 'dart:convert';
import 'dart:io';

import 'package:clipshare/core/database/app_database.dart';
import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/database/dao/app_info_dao.dart';
import 'package:clipshare/core/database/dao/device_dao.dart';
import 'package:clipshare/core/database/dao/history_dao.dart';
import 'package:clipshare/core/database/dao/history_tag_dao.dart';
import 'package:clipshare/core/database/dao/operation_record_dao.dart';
import 'package:clipshare/core/database/dao/rule_dao.dart';
import 'package:clipshare/core/database/dao/script_module_dao.dart';
import 'package:clipshare/core/database/extensions/history_extension.dart';
import 'package:clipshare/core/database/tables/device.dart';
import 'package:clipshare/core/database/tables/history.dart';
import 'package:clipshare/core/database/tables/history_tag.dart';
import 'package:clipshare/core/database/tables/operation_record.dart';
import 'package:clipshare/core/database/tables/rule.dart';
import 'package:clipshare/core/database/tables/script_module.dart';
import 'package:clipshare/core/extensions/file_extension.dart';
import 'package:clipshare/core/runtime/snowflake/id_provider.dart';
import 'package:clipshare/core/services/clipboard/clipboard_source_provider.dart';
import 'package:clipshare/core/services/device/local_device_info.dart';
import 'package:clipshare/core/services/device/local_device_info_provider.dart';
import 'package:clipshare/core/services/transport/enums/msg_type.dart';
import 'package:clipshare/core/services/transport/message_sender/message_sender_provider.dart';
import 'package:clipshare/core/services/transport/message_sync/message_sync_provider.dart';
import 'package:clipshare/core/services/transport/models/sync_payload.dart';
import 'package:clipshare/core/settings/sync/sync_settings_provider.dart';
import 'package:clipshare/shared/models/module.dart';
import 'package:clipshare/shared/models/op_method.dart';
import 'package:clipshare/shared/utils/snowflake.dart';
import 'package:drift/drift.dart' show Value;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sync_push_provider.g.dart';

/// 负责把本地操作记录补全为同步载荷并推送给对端，
/// 与接收侧的 [MessageSyncNotifier] 事件流成对存在。
@Riverpod(keepAlive: true)
class SyncPushNotifier extends _$SyncPushNotifier {
  /// 补数消息之间的节流间隔，避免大批量补数瞬间打满链路。
  static const _missingDataInterval = Duration(milliseconds: 50);

  ///时区偏移配置
  final _timeZoneOffsetSeconds = DateTime.now().timeZoneOffset.inSeconds;

  AppDatabase get _db => ref.read(appDbProvider).requireValue;

  OperationRecordDao get _opRecordDao => _db.operationRecordDao;

  HistoryDao get _historyDao => _db.historyDao;

  HistoryTagDao get _historyTagDao => _db.historyTagDao;

  DeviceDao get _deviceDao => _db.deviceDao;

  RuleDao get _ruleDao => _db.ruleDao;

  ScriptModuleDao get _scriptModuleDao => _db.scriptModuleDao;

  AppInfoDao get _appInfoDao => _db.appInfoDao;

  MessageSenderNotifier get _messageSender => ref.read(messageSenderProvider.notifier);

  Snowflake get _snowflake => ref.read(idProvider);

  BaseDeviceInfo get _baseDevInfo => ref.read(localDeviceInfoProvider).requireValue.baseDeviceInfo;

  @override
  void build() {}

  /// 按模块把操作记录补全为完整同步载荷。
  /// 实体已被删除且操作本身不是删除时，[SyncPayload.shouldRemove] 为 true，
  /// 调用方应清理该本地记录而不是继续发送。
  Future<SyncPayload> _buildPayload(OperationRecord record) async {
    final Future<bool> Function(OperationRecord, Map<String, dynamic>) processFunc;
    switch (record.module) {
      case Module.device:
        processFunc = _processDevicePayload;
        break;
      case Module.tag:
        processFunc = _processTagPayload;
        break;
      case Module.history:
        processFunc = _processHistoryPayload;
        break;
      case Module.historyTop:
      case Module.historySource:
        processFunc = _processHistoryTopOrSourcePayload;
        break;
      case Module.rule:
        processFunc = _processRulePayload;
        break;
      case Module.scriptModule:
        processFunc = _processScriptModulePayload;
        break;
      case Module.appInfo:
        processFunc = _processAppInfoPayload;
        break;
      default:
        throw 'UnSupported module: ${record.module.name}';
    }
    final payload = record.toJson();
    final shouldRemove = await processFunc(record, payload);
    return SyncPayload(shouldRemove: shouldRemove, data: payload);
  }

  ///region process payload

  Future<bool> _processDevicePayload(OperationRecord record, Map<String, dynamic> payload) async {
    var shouldRemove = false;
    final device = await _deviceDao.getById(record.data);
    if (device == null) {
      if (record.method == OpMethod.delete) {
        payload['data'] = emptyDevice(guid: record.data).toJson();
      } else {
        shouldRemove = true;
      }
    } else {
      payload['data'] = device.toJson();
    }
    return shouldRemove;
  }

  Future<bool> _processTagPayload(OperationRecord record, Map<String, dynamic> payload) async {
    var shouldRemove = false;
    final id = int.parse(record.data);
    final tag = await _historyTagDao.getById(id);
    if (tag == null) {
      if (record.method == OpMethod.delete) {
        payload['data'] = emptyHistoryTag(id: id).toJson();
      } else {
        shouldRemove = true;
      }
    } else {
      payload['data'] = tag.toJson();
    }
    return shouldRemove;
  }

  Future<bool> _processHistoryPayload(OperationRecord record, Map<String, dynamic> payload) async {
    var shouldRemove = false;
    final id = int.parse(record.data);
    final history = await _historyDao.getById(id);
    if (history == null) {
      if (record.method == OpMethod.delete) {
        payload['data'] = emptyHistory(id: id).toJson();
      } else {
        shouldRemove = true;
      }
    } else {
      final historyPayload = await _buildHistoryPayload(history);
      if (historyPayload == null) {
        shouldRemove = true;
      } else {
        payload['data'] = historyPayload;
      }
    }
    return shouldRemove;
  }

  Future<bool> _processHistoryTopOrSourcePayload(OperationRecord record, Map<String, dynamic> payload) async {
    var shouldRemove = false;
    final id = int.parse(record.data);
    final history = await _historyDao.getById(id);
    if (history == null) {
      if (record.method == OpMethod.delete) {
        payload['data'] = emptyHistory(id: id).toJson();
      } else {
        shouldRemove = true;
      }
    } else {
      // 这两个模块只关心主键对应的单个字段，正文置空可显著减小传输量
      payload['data'] = history.copyWith(content: '', extracted: const Value(null)).toJson();
    }
    return shouldRemove;
  }

  Future<bool> _processRulePayload(OperationRecord record, Map<String, dynamic> payload) async {
    var shouldRemove = false;
    final id = int.parse(record.data);
    final rule = await _ruleDao.getById(id);
    if (rule == null) {
      if (record.method == OpMethod.delete) {
        payload['data'] = ruleToSyncPayload(emptyRule().copyWith(id: id));
      } else {
        shouldRemove = true;
      }
    } else {
      payload['data'] = ruleToSyncPayload(rule);
    }
    return shouldRemove;
  }

  Future<bool> _processScriptModulePayload(OperationRecord record, Map<String, dynamic> payload) async {
    var shouldRemove = false;
    final module = await _scriptModuleDao.getByName(record.data);
    if (module == null) {
      if (record.method == OpMethod.delete) {
        payload['data'] = scriptModuleToSyncPayload(
          emptyScriptModule().copyWith(moduleName: record.data),
        );
      } else {
        shouldRemove = true;
      }
    } else {
      payload['data'] = scriptModuleToSyncPayload(module);
    }
    return shouldRemove;
  }

  Future<bool> _processAppInfoPayload(OperationRecord record, Map<String, dynamic> payload) async {
    var shouldRemove = false;
    final appInfo = await _appInfoDao.getById(int.parse(record.data));
    if (appInfo == null) {
      shouldRemove = true;
    } else {
      // 旧协议中来源信息以 JSON 字符串承载，对端按字符串解析
      payload['data'] = jsonEncode(appInfo.toJson());
    }
    return shouldRemove;
  }

  ///endregion

  /// 推送单条操作记录到所有在线设备。
  Future<void> pushRecord(OperationRecord record) async {
    final payload = await _buildPayload(record);
    if (payload.shouldRemove) {
      await _opRecordDao.deleteByIds([record.id]);
      return;
    }
    await _messageSender.sendToAll(MsgType.sync, payload.data);
  }

  /// 响应 reqMissingData，把本机尚未被目标设备同步过的记录补推过去。
  /// [fromDevId] 为请求方设备，来源信息也只补推请求方已安装应用对应的条目。
  Future<void> sendMissingData({
    required BaseDeviceInfo targetDev,
    required String fromDevId,
    required List<String> syncedAppIds,
  }) async {
    final syncOutdateLimitTime = ref.read(syncSettingsProvider).requireValue.syncOutdateLimitTime;
    final records = await _opRecordDao.getSyncRecord(
      targetDev.guid,
      fromDevId,
      syncOutdateLimitTime,
      _timeZoneOffsetSeconds,
    );
    // 来源信息没有操作记录，需要按请求方已同步的列表临时补齐
    final pending = [
      ..._buildUnsyncedAppInfoRecords(fromDevId, syncedAppIds),
      ...records,
    ];
    for (var i = 0; i < pending.length; i++) {
      final record = pending[i];
      final payload = await _buildPayload(record);
      if (payload.shouldRemove) {
        await _opRecordDao.deleteByIds([record.id]);
        continue;
      }
      await _messageSender.sendToDevice(targetDev.guid, MsgType.missingData, {
        'data': payload.data,
        'total': pending.length,
        'seq': i + 1,
      });
      await Future.delayed(_missingDataInterval);
    }
  }

  /// 图片记录的正文以文件字节内嵌，返回 null 表示本地文件已丢失。
  Future<Map<String, dynamic>?> _buildHistoryPayload(History history) async {
    final payload = history.toJson();
    if (!history.isImage) {
      return payload;
    }
    final file = File(history.content);
    if (!file.existsSync()) {
      return null;
    }
    payload['content'] = {
      'fileName': file.fileName,
      'data': await file.readAsBytes(),
    };
    return payload;
  }

  /// 构造请求方已安装、但其未同步的来源信息记录，这些记录只用于本次推送，不落库。
  List<OperationRecord> _buildUnsyncedAppInfoRecords(String fromDevId, List<String> syncedAppIds) {
    final appInfos = ref.read(clipboardSourceProvider).value?.appInfos ?? const <AppInfo>[];
    return appInfos
        .where((item) => item.devId == fromDevId && !syncedAppIds.contains(item.appId))
        .map(
          (item) => newOperationRecord(
            _snowflake,
            _baseDevInfo,
            Module.appInfo,
            OpMethod.add,
            item.id,
          ),
        )
        .toList();
  }
}
