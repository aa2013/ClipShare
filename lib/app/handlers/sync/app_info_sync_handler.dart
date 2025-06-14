import 'dart:convert';

import 'package:clipshare/app/data/enums/module.dart';
import 'package:clipshare/app/data/enums/msg_type.dart';
import 'package:clipshare/app/data/enums/op_method.dart';
import 'package:clipshare/app/data/models/message_data.dart';
import 'package:clipshare/app/data/repository/entity/tables/app_info.dart';
import 'package:clipshare/app/data/repository/entity/tables/history.dart';
import 'package:clipshare/app/data/repository/entity/tables/operation_record.dart';
import 'package:clipshare/app/data/repository/entity/tables/operation_sync.dart';
import 'package:clipshare/app/modules/history_module/history_controller.dart';
import 'package:clipshare/app/services/clipboard_source_service.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/services/socket_service.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:get/get.dart';

/// app信息同步处理器
class AppInfoSyncHandler implements SyncListener {
  final appConfig = Get.find<ConfigService>();
  final dbService = Get.find<DbService>();
  final sourceService = Get.find<ClipboardSourceService>();
  final sktService = Get.find<SocketService>();
  final historyController = Get.find<HistoryController>();
  static String tag = "AppInfoSyncHandler";

  AppInfoSyncHandler() {
    sktService.addSyncListener(Module.appInfo, this);
  }

  void dispose() {
    sktService.removeSyncListener(Module.appInfo, this);
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
    Log.debug(tag, "onSync ${map["data"]}");
    final appInfoMap = jsonDecode(map["data"]) as Map<String, dynamic>;
    map["data"] = "";
    var opRecord = OperationRecord.fromJson(map);
    var appInfo = AppInfo.fromJson(appInfoMap.cast());
    bool success = false;
    switch (opRecord.method) {
      case OpMethod.add:
      case OpMethod.update:
        success = await sourceService.addOrUpdate(appInfo);
        break;
      default:
    }
    if (success) {
      //同步成功后在本地也记录一次
      var originOpRecord = opRecord.copyWith(appInfo.id.toString());
      await dbService.opRecordDao.add(originOpRecord);
    }
    historyController.updateData(
          (his) => his.source == appInfo.appId,
          (his) => {},
    );
    //发送同步确认
    sktService.sendData(
      send,
      MsgType.ackSync,
      {"id": opRecord.id, "module": Module.appInfo.moduleName},
    );
  }
}
