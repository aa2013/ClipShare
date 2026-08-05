import 'package:clipshare/app/data/enums/module.dart';
import 'package:clipshare/app/data/enums/op_method.dart';
import 'package:clipshare/app/data/models/message_data.dart';
import 'package:clipshare/app/data/repository/entity/tables/device.dart';
import 'package:clipshare/app/data/repository/entity/tables/operation_record.dart';
import 'package:clipshare/app/data/repository/entity/tables/operation_sync.dart';
import 'package:clipshare/app/data/repository/entity/tables/rule.dart';
import 'package:clipshare/app/handlers/sync/abstract_data_sender.dart';
import 'package:clipshare/app/handlers/sync/storage_sync_record_helper.dart';
import 'package:clipshare/app/listeners/sync_listener.dart';
import 'package:clipshare/app/modules/rules_module/rules_controller.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:get/get.dart';

class RuleSyncHandler implements SyncListener {
  final appConfig = Get.find<ConfigService>();
  final dbService = Get.find<DbService>();
  final ruleController = Get.find<RulesController>();
  static const module = Module.rule;

  RuleSyncHandler() {
    DataSender.addSyncListener(module, this);
  }

  void dispose() {
    DataSender.removeSyncListener(module, this);
  }

  @override
  Future ackSync(MessageData msg) {
    var send = msg.send;
    var data = msg.data;
    var opSync = OperationSync(
      opId: data["id"],
      devId: send.guid,
      uid: appConfig.userId,
    );
    return dbService.opSyncDao.add(opSync);
  }

  @override
  Future onSync(MessageData msg) async {
    final map = msg.data;
    await _syncData(msg.send.guid, map);
  }

  Future<OperationRecord?> _syncData(
    String senderDevId,
    Map<String, dynamic> map, {
    bool fromStorage = false,
  }) async {
    final ruleMap = map["data"] as Map<dynamic, dynamic>;
    map["data"] = "";
    final opRecord = OperationRecord.fromJson(map);
    final rule = Rule.fromJson(ruleMap.cast());
    var success = false;
    switch (opRecord.method) {
      case OpMethod.add:
      case OpMethod.update:
        final dbData = await dbService.ruleDao.getById(rule.id);
        if (dbData != null) {
          if (dbData.version >= rule.version) {
            break;
          }
          await dbService.opRecordDao.deleteByDataWithCascade(rule.id.toString());
          await dbService.ruleDao.remove(rule.id);
        } else {
          await dbService.opRecordDao.deleteByDataWithCascade(rule.id.toString());
        }
        success = (await dbService.ruleDao.addRule(rule)) > 0;
        if (success) {
          ruleController.addOrUpdateRule(rule);
          opRecord.data = rule.id.toString();
        }
        break;
      case OpMethod.delete:
        success = (await dbService.ruleDao.remove(rule.id) ?? 0) > 0;
        if (success) {
          await dbService.opRecordDao.deleteByDataWithCascade(rule.id.toString());
          ruleController.rules.removeWhere((e) => e.id == rule.id);
        }
        break;
      default:
    }
    if (!success) {
      return null;
    }
    // 规则来自存储回放时，要保留 storageSync 标记，避免版本合并后再次回灌到云端。
    final localOpRecord = fromStorage
        ? StorageSyncRecordHelper.copyWithStorageData(opRecord, opRecord.data)
        : opRecord;
    await dbService.opRecordDao.add(localOpRecord);
    await dbService.opSyncDao.add(
      OperationSync(opId: localOpRecord.id, devId: senderDevId, uid: appConfig.userId),
    );
    return localOpRecord;
  }

  @override
  Future<void> onStorageSync(
    Map<String, dynamic> map,
    Device sender,
    bool loadingMissingData,
  ) async {
    // sender.guid 仍然要写入 opSync，避免后续缺失数据同步再次把同一条规则推回来。
    await _syncData(sender.guid, map, fromStorage: true);
  }
}
