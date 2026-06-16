import 'dart:convert';

import 'package:clipshare/app/data/enums/module.dart';
import 'package:clipshare/app/data/enums/msg_type.dart';
import 'package:clipshare/app/data/enums/op_method.dart';
import 'package:clipshare/app/data/models/message_data.dart';
import 'package:clipshare/app/data/repository/entity/tables/app_info.dart';
import 'package:clipshare/app/data/repository/entity/tables/device.dart';
import 'package:clipshare/app/data/repository/entity/tables/operation_record.dart';
import 'package:clipshare/app/data/repository/entity/tables/operation_sync.dart';
import 'package:clipshare/app/handlers/sync/abstract_data_sender.dart';
import 'package:clipshare/app/handlers/sync/storage_sync_record_helper.dart';
import 'package:clipshare/app/listeners/sync_listener.dart';
import 'package:clipshare/app/modules/history_module/history_controller.dart';
import 'package:clipshare/app/services/clipboard_source_service.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/utils/extensions/device_extension.dart';
import 'package:get/get.dart';

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
    return dbService.opSyncDao.add(opSync);
  }

  @override
  Future onSync(MessageData msg) async {
    var sender = msg.send;
    final map = msg.data;
    final opRecord = await _syncData(map);
    sender.sendData(
      MsgType.ackSync,
      {"id": opRecord.id, "module": Module.appInfo.moduleName},
    );
  }

  Future<OperationRecord> _syncData(
    Map<String, dynamic> map, {
    bool fromStorage = false,
  }) async {
    final appInfoMap = jsonDecode(map["data"]) as Map<String, dynamic>;
    map["data"] = "";
    final opRecord = OperationRecord.fromJson(map);
    final appInfo = AppInfo.fromJson(appInfoMap.cast());
    var success = false;
    switch (opRecord.method) {
      case OpMethod.add:
      case OpMethod.update:
        success = await sourceService.addOrUpdate(appInfo);
        break;
      default:
    }
    if (success) {
      // 存储回放成功后同样要保留 storageSync 标记，避免本地把远端记录再次补传出去。
      final originOpRecord = fromStorage
          ? StorageSyncRecordHelper.copyWithStorageData(opRecord, appInfo.id.toString())
          : opRecord.copyWith(data: appInfo.id.toString());
      await dbService.opRecordDao.add(originOpRecord);
    }
    historyController.updateData(
      (his) => his.source == appInfo.appId,
      (his) => {},
    );
    return opRecord;
  }

  @override
  Future<void> onStorageSync(
    Map<String, dynamic> map,
    Device sender,
    bool loadingMissingData,
  ) async {
    // 存储模式和直连共用同一套落库逻辑，只在本地记录阶段补上 storageSync 标记。
    await _syncData(map, fromStorage: true);
  }
}
