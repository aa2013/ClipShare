import 'package:clipshare/app/data/enums/module.dart';
import 'package:clipshare/app/data/enums/op_method.dart';
import 'package:clipshare/app/data/models/message_data.dart';
import 'package:clipshare/app/data/repository/entity/tables/device.dart';
import 'package:clipshare/app/data/repository/entity/tables/history.dart';
import 'package:clipshare/app/data/repository/entity/tables/operation_record.dart';
import 'package:clipshare/app/data/repository/entity/tables/operation_sync.dart';
import 'package:clipshare/app/handlers/sync/ack_sync_sender.dart';
import 'package:clipshare/app/handlers/sync/abstract_data_sender.dart';
import 'package:clipshare/app/handlers/sync/storage_sync_record_helper.dart';
import 'package:clipshare/app/listeners/sync_listener.dart';
import 'package:clipshare/app/modules/history_module/history_controller.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:get/get.dart';

class HistoryTopSyncHandler implements SyncListener {
  final appConfig = Get.find<ConfigService>();
  final dbService = Get.find<DbService>();
  final historyController = Get.find<HistoryController>();

  HistoryTopSyncHandler() {
    DataSender.addSyncListener(Module.historyTop, this);
  }

  void dispose() {
    DataSender.removeSyncListener(Module.historyTop, this);
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
    await AckSyncSender.send(
      sender,
      opRecord.id,
      {"id": opRecord.id, "module": Module.historyTop.moduleName},
    );
  }

  Future<OperationRecord> _syncData(
    Map<String, dynamic> map, {
    bool fromStorage = false,
  }) async {
    final historyMap = map["data"] as Map<dynamic, dynamic>;
    map["data"] = "";
    final opRecord = OperationRecord.fromJson(map);
    final history = History.fromJson(historyMap.cast());
    var success = false;
    switch (opRecord.method) {
      case OpMethod.update:
        success = await dbService.historyDao.setTop(history.id, history.top).then((cnt) => cnt ?? 0) > 0;
        break;
      default:
    }
    if (success) {
      // 存储回放后的置顶记录要标记为已同步，避免被本机重新写回存储形成回环。
      final originOpRecord = fromStorage
          ? StorageSyncRecordHelper.copyWithStorageData(opRecord, history.id.toString())
          : opRecord.copyWith(data: history.id.toString());
      await dbService.opRecordDao.add(originOpRecord);
    }
    historyController.updateData(
      (his) => his.id == history.id,
      (his) => his.top = history.top,
    );
    return opRecord;
  }

  @override
  Future<void> onStorageSync(
    Map<String, dynamic> map,
    Device sender,
    bool loadingMissingData,
  ) async {
    // 直连和存储共用置顶更新逻辑，区别只在本地操作记录的 storageSync 状态。
    await _syncData(map, fromStorage: true);
  }
}
