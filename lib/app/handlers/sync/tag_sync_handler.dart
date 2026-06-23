import 'package:clipshare/app/data/enums/module.dart';
import 'package:clipshare/app/data/enums/op_method.dart';
import 'package:clipshare/app/data/models/message_data.dart';
import 'package:clipshare/app/data/repository/entity/tables/device.dart';
import 'package:clipshare/app/data/repository/entity/tables/history_tag.dart';
import 'package:clipshare/app/data/repository/entity/tables/operation_record.dart';
import 'package:clipshare/app/data/repository/entity/tables/operation_sync.dart';
import 'package:clipshare/app/handlers/sync/ack_sync_sender.dart';
import 'package:clipshare/app/handlers/sync/abstract_data_sender.dart';
import 'package:clipshare/app/handlers/sync/storage_sync_record_helper.dart';
import 'package:clipshare/app/listeners/sync_listener.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/services/tag_service.dart';
import 'package:get/get.dart';

class TagSyncHandler implements SyncListener {
  final appConfig = Get.find<ConfigService>();
  final dbService = Get.find<DbService>();
  final tagService = Get.find<TagService>();

  TagSyncHandler() {
    DataSender.addSyncListener(Module.tag, this);
  }

  void dispose() {
    DataSender.removeSyncListener(Module.tag, this);
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
      {"id": opRecord.id, "module": Module.tag.moduleName},
    );
  }

  Future<OperationRecord> _syncData(
    Map<String, dynamic> map, {
    bool fromStorage = false,
  }) async {
    final tagMap = map["data"] as Map<dynamic, dynamic>;
    map["data"] = "";
    final opRecord = OperationRecord.fromJson(map);
    final tag = HistoryTag.fromJson(tagMap.cast());
    var success = false;
    switch (opRecord.method) {
      case OpMethod.add:
        success = await dbService.historyTagDao.add(tag) > 0;
        tagService.add(tag, false);
        break;
      case OpMethod.delete:
        final dbTag = await dbService.historyTagDao.getById(tag.id);
        success = await dbService.historyTagDao.removeById(tag.id).then((cnt) => cnt ?? 0) > 0;
        if (dbTag != null) {
          tagService.remove(dbTag, false);
        }
        break;
      default:
    }
    if (success) {
      // 标签在存储模式下落库后也要记录为已同步，否则删除/新增标签会被本地重复补传。
      final localOpRecord = fromStorage
          ? StorageSyncRecordHelper.copyWithStorageData(opRecord, tag.id.toString())
          : opRecord.copyWith(data: tag.id.toString());
      await dbService.opRecordDao.add(localOpRecord);
    }
    return opRecord;
  }

  @override
  Future<void> onStorageSync(
    Map<String, dynamic> map,
    Device sender,
    bool loadingMissingData,
  ) async {
    // 复用直连分支的增删逻辑，只在本地 opRecord 上补 storageSync 标记。
    await _syncData(map, fromStorage: true);
  }
}
