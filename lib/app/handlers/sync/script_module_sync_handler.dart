import 'package:clipshare/app/data/enums/module.dart';
import 'package:clipshare/app/data/enums/op_method.dart';
import 'package:clipshare/app/data/models/message_data.dart';
import 'package:clipshare/app/data/repository/entity/tables/device.dart';
import 'package:clipshare/app/data/repository/entity/tables/operation_record.dart';
import 'package:clipshare/app/data/repository/entity/tables/operation_sync.dart';
import 'package:clipshare/app/data/repository/entity/tables/script_module.dart';
import 'package:clipshare/app/handlers/sync/ack_sync_sender.dart';
import 'package:clipshare/app/handlers/sync/abstract_data_sender.dart';
import 'package:clipshare/app/handlers/sync/storage_sync_record_helper.dart';
import 'package:clipshare/app/listeners/sync_listener.dart';
import 'package:clipshare/app/modules/rules_module/rules_controller.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:get/get.dart';

class ScriptModuleSyncHandler implements SyncListener {
  final appConfig = Get.find<ConfigService>();
  final dbService = Get.find<DbService>();
  final ruleController = Get.find<RulesController>();
  static const module = Module.scriptModule;

  ScriptModuleSyncHandler() {
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
    var sender = msg.send;
    final map = msg.data;
    final opRecord = await _syncData(msg.send.guid, map);
    if (opRecord == null) {
      return;
    }
    await AckSyncSender.send(
      sender,
      opRecord.id,
      {"id": opRecord.id, "module": module.name},
    );
  }

  Future<OperationRecord?> _syncData(
    String senderDevId,
    Map<String, dynamic> map, {
    bool fromStorage = false,
  }) async {
    final ruleMap = map["data"] as Map<dynamic, dynamic>;
    map["data"] = "";
    final opRecord = OperationRecord.fromJson(map);
    final ruleLib = ScriptModule.fromJson(ruleMap.cast());
    var success = false;
    await dbService.opRecordDao.deleteByDataWithCascade(ruleLib.moduleName);
    switch (opRecord.method) {
      case OpMethod.add:
      case OpMethod.update:
        final dbData = await dbService.scriptModuleDao.getByName(ruleLib.moduleName);
        if (dbData != null) {
          if (dbData.version >= ruleLib.version) {
            break;
          }
          await dbService.scriptModuleDao.remove(ruleLib.moduleName);
        }
        success = (await dbService.scriptModuleDao.addModule(ruleLib)) > 0;
        if (success) {
          ruleController.addOrUpdateRuleLib(ruleLib);
          opRecord.data = ruleLib.moduleName;
        }
        break;
      case OpMethod.delete:
        success = (await dbService.scriptModuleDao.remove(ruleLib.moduleName) ?? 0) > 0;
        if (success) {
          ruleController.scriptModules.removeWhere((e) => e.moduleName == ruleLib.moduleName);
        }
        break;
      default:
    }
    if (!success) {
      return null;
    }
    // 脚本模块会先清理同名旧记录，存储回放后必须把新记录直接标记为已完成存储同步。
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
    // sender.guid 需要保留到 opSync，用来阻止相同脚本模块在后续同步中反复互推。
    await _syncData(sender.guid, map, fromStorage: true);
  }
}
