import 'package:clipshare/app/data/enums/module.dart';
import 'package:clipshare/app/data/enums/msg_type.dart';
import 'package:clipshare/app/data/enums/op_method.dart';
import 'package:clipshare/app/data/models/message_data.dart';
import 'package:clipshare/app/data/repository/entity/tables/device.dart';
import 'package:clipshare/app/data/repository/entity/tables/history.dart';
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

class HistorySourceSyncHandler implements SyncListener {
  final appConfig = Get.find<ConfigService>();
  final dbService = Get.find<DbService>();
  final historyController = Get.find<HistoryController>();
  final sourceService = Get.find<ClipboardSourceService>();

  HistorySourceSyncHandler() {
    DataSender.addSyncListener(Module.historySource, this);
  }

  void dispose() {
    DataSender.removeSyncListener(Module.historySource, this);
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
      {"id": opRecord.id, "module": Module.historySource.moduleName},
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
        final source = history.source;
        var cnt = 0;
        if (source != null) {
          cnt = await dbService.historyDao.updateHistorySource(history.id, source) ?? 0;
        } else {
          cnt = await dbService.historyDao.clearHistorySource(history.id) ?? 0;
        }
        success = cnt > 0;
        if (success) {
          await sourceService.removeNotUsed();
        }
        break;
      case OpMethod.delete:
        final id = history.id;
        await dbService.historyDao.clearHistorySource(id);
        await sourceService.removeNotUsed();
      default:
    }
    if (success) {
      await dbService.opRecordDao.deleteHistorySourceRecords(
        history.id,
        Module.historySource.moduleName,
      );
      // 删除旧来源记录后再补写一条本地 opRecord，避免缺失数据链路留下重复来源操作。
      final originOpRecord = fromStorage
          ? StorageSyncRecordHelper.copyWithStorageData(opRecord, history.id.toString())
          : opRecord.copyWith(data: history.id.toString());
      await dbService.opRecordDao.add(originOpRecord);
    }
    historyController.updateData(
      (his) => his.id == history.id,
      (his) => his.source = history.source,
    );
    return opRecord;
  }

  @override
  Future<void> onStorageSync(
    Map<String, dynamic> map,
    Device sender,
    bool loadingMissingData,
  ) async {
    // 存储同步只需要沿用既有更新逻辑，并在落本地 opRecord 时标记已完成存储同步。
    await _syncData(map, fromStorage: true);
  }
}
