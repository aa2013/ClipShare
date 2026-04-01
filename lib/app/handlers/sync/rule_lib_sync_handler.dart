import 'dart:convert';

import 'package:clipshare/app/data/enums/module.dart';
import 'package:clipshare/app/data/enums/msg_type.dart';
import 'package:clipshare/app/data/enums/op_method.dart';
import 'package:clipshare/app/data/enums/rule_type.dart';
import 'package:clipshare/app/data/models/message_data.dart';
import 'package:clipshare/app/data/repository/entity/tables/device.dart';
import 'package:clipshare/app/data/repository/entity/tables/lua_lib.dart';
import 'package:clipshare/app/data/repository/entity/tables/operation_record.dart';
import 'package:clipshare/app/data/repository/entity/tables/operation_sync.dart';
import 'package:clipshare/app/data/repository/entity/tables/rule.dart';
import 'package:clipshare/app/handlers/sync/abstract_data_sender.dart';
import 'package:clipshare/app/listeners/sync_listener.dart';
import 'package:clipshare/app/modules/rules_module/rules_controller.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/utils/extensions/device_extension.dart';
import 'package:get/get.dart';

///规则同步器
class RuleLibSyncHandler implements SyncListener {
  final appConfig = Get.find<ConfigService>();
  final dbService = Get.find<DbService>();
  final ruleController = Get.find<RulesController>();
  static const module = Module.ruleLib;

  RuleLibSyncHandler() {
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
    //记录同步记录
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
    //发送同步确认
    sender.sendData(
      MsgType.ackSync,
      {"id": opRecord.id, "module": module.name},
    );
  }

  Future<OperationRecord?> _syncData(String senderDevId, Map<String, dynamic> map) async {
    final ruleMap = map["data"] as Map<dynamic, dynamic>;
    map["data"] = "";
    final opRecord = OperationRecord.fromJson(map);
    final ruleLib = RuleLib.fromJson(ruleMap.cast());
    bool success = false;
    //删除所有操作记录
    await dbService.opRecordDao.deleteByDataWithCascade(ruleLib.libName);
    switch (opRecord.method) {
      case OpMethod.add:
      case OpMethod.update:
        final dbData = await dbService.ruleLibDao.getByLibName(ruleLib.libName);
        if (dbData != null) {
          //版本比自己老，忽略
          if (dbData.version >= ruleLib.version) {
            break;
          }
          await dbService.ruleLibDao.remove(ruleLib.libName);
        }
        success = (await dbService.ruleLibDao.addLib(ruleLib)) > 0;
        if (success) {
          ruleController.addOrUpdateRuleLib(ruleLib);
          opRecord.data = ruleLib.libName;
        }
        break;
      case OpMethod.delete:
        success = (await dbService.ruleLibDao.remove(ruleLib.libName) ?? 0) > 0;
        if (success) {
          ruleController.ruleLibs.removeWhere((e) => e.libName == ruleLib.libName);
        }
        break;
      default:
    }
    if (success) {
      //增加本机操作记录
      await dbService.opRecordDao.add(opRecord);
      //将发送方写入同步几乎防止重复同步
      await dbService.opSyncDao.add(OperationSync(opId: opRecord.id, devId: senderDevId, uid: appConfig.userId));
    } else {
      return null;
    }
    return opRecord;
  }

  @override
  Future<void> onStorageSync(Map<String, dynamic> map, Device sender, bool loadingMissingData) async {
    //todo 存储中转实现
    await _syncData(sender.guid, map);
  }
}
