import 'dart:convert';

import 'package:clipshare/app/data/enums/module.dart';
import 'package:clipshare/app/data/enums/msg_type.dart';
import 'package:clipshare/app/data/enums/rule_type.dart';
import 'package:clipshare/app/data/models/message_data.dart';
import 'package:clipshare/app/data/repository/entity/tables/operation_record.dart';
import 'package:clipshare/app/data/repository/entity/tables/operation_sync.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/services/socket_service.dart';
import 'package:get/get.dart';

///规则同步器
class RulesSyncHandler implements SyncListener {
  final sktService = Get.find<SocketService>();
  final appConfig = Get.find<ConfigService>();
  final dbService = Get.find<DbService>();

  RulesSyncHandler() {
    sktService.addSyncListener(Module.rules, this);
  }

  void dispose() {
    sktService.removeSyncListener(Module.rules, this);
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
    var send = msg.send;
    final map = msg.data;
    final ruleMap = jsonDecode(map["data"]) as Map<dynamic, dynamic>;
    print(ruleMap);
    map["data"] = "";
    var opRecord = OperationRecord.fromJson(map);
    RuleType rule = RuleType.getValue(ruleMap["rule"]);
    Map<String, dynamic> data =
        (ruleMap["data"] as Map<dynamic, dynamic>).cast();
    int newVersion = data["version"];
    dynamic localTagRules = {};
    switch (rule) {
      case RuleType.tag:
        localTagRules = jsonDecode(appConfig.tagRules);
        break;
      case RuleType.sms:
        localTagRules = jsonDecode(appConfig.smsRules);
        break;
      default:
    }

    var localVersion = localTagRules["version"];
    if (localVersion <= newVersion) {
      //小于发送过来的版本，更新本地
      switch (rule) {
        case RuleType.tag:
          await appConfig.setTagRules(jsonEncode(data));
          break;
        case RuleType.sms:
          await appConfig.setSmsRules(jsonEncode(data));
          break;
        default:
          return;
      }
      //本地插入一条操作记录，先移除旧的再插入
      await dbService.opRecordDao.removeRuleRecord(
        RuleType.tag.name,
        appConfig.userId,
      );
      await dbService.opRecordDao.add(opRecord);
    }
    //发送同步确认
    sktService.sendData(
      send,
      MsgType.ackSync,
      {"id": opRecord.id, "module": Module.rules.moduleName},
    );
  }
}
