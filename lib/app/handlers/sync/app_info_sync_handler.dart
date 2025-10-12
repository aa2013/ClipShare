import 'dart:convert';

import 'package:clipshare/app/data/enums/module.dart';
import 'package:clipshare/app/data/enums/msg_type.dart';
import 'package:clipshare/app/data/enums/op_method.dart';
import 'package:clipshare/app/data/models/message_data.dart';
import 'package:clipshare/app/data/repository/entity/tables/app_info.dart';
import 'package:clipshare/app/data/repository/entity/tables/device.dart';
import 'package:clipshare/app/data/repository/entity/tables/history.dart';
import 'package:clipshare/app/data/repository/entity/tables/operation_record.dart';
import 'package:clipshare/app/data/repository/entity/tables/operation_sync.dart';
import 'package:clipshare/app/handlers/sync/abstract_data_sender.dart';
import 'package:clipshare/app/listeners/sync_listener.dart';
import 'package:clipshare/app/modules/history_module/history_controller.dart';
import 'package:clipshare/app/services/clipboard_source_service.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/services/transport/socket_service.dart';
import 'package:clipshare/app/utils/extensions/device_extension.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:get/get.dart';

/// app信息同步处理器
class AppInfoSyncHandler implements SyncListener {
  final appConfig = Get.find<ConfigService>();
  final dbService = Get.find<DbService>();
  final sourceService = Get.find<ClipboardSourceService>();
  final historyController = Get.find<HistoryController>();
  static String tag = "AppInfoSyncHandler";

  AppInfoSyncHandler() {
    DataSender.addSyncListener(Module.appInfo, this);
  }

  void dispose() {
    DataSender.removeSyncListener(Module.appInfo, this);
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
    final opRecord = await _syncData(map);
    //发送同步确认
    sender.sendData(
      MsgType.ackSync,
      {"id": opRecord.id, "module": Module.appInfo.moduleName},
    );
  }

  Future<OperationRecord> _syncData(Map<String, dynamic> map) async {
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
      var originOpRecord = opRecord.copyWith(data: appInfo.id.toString());
      await dbService.opRecordDao.add(originOpRecord);
    }
    historyController.updateData(
      (his) => his.source == appInfo.appId,
      (his) => {},
    );
    return opRecord;
  }

  @override
  Future<void> onStorageSync(Map<String, dynamic> map, Device sender, bool loadingMissingData) async {
    await _syncData(map);
  }
}
