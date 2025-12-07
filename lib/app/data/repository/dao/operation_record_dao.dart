import 'package:clipshare/app/data/enums/module.dart';
import 'package:clipshare/app/data/enums/msg_type.dart';
import 'package:clipshare/app/data/enums/op_method.dart';
import 'package:clipshare/app/handlers/sync/abstract_data_sender.dart';
import 'package:clipshare/app/handlers/sync/missing_data_sync_handler.dart';
import 'package:clipshare/app/services/clipboard_source_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/services/transport/socket_service.dart';
import 'package:clipshare/app/services/transport/storage_service.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:floor/floor.dart';
import 'package:get/get.dart';

import '../entity/tables/operation_record.dart';

@dao
abstract class OperationRecordDao {
  final dbService = Get.find<DbService>();
  static const tag = "OperationRecordDao";

  ///添加操作记录
  @Insert(onConflict: OnConflictStrategy.ignore)
  Future<int> add(OperationRecord record);

  ///添加操作记录并发送通知设备更改
  Future<int> addAndNotify(OperationRecord record) async {
    final cnt = await add(record);
    if (cnt == 0) return cnt;
    //发送变更至已连接的所有设备
    final result = await MissingDataSyncHandler.process(record);
    await DataSender.sendData2All(MsgType.sync, result.result);
    return cnt;
  }

  ///获取某用户某设备的未同步记录
  @Query("""
  select * from OperationRecord record
  where not exists (
    select 1 from OperationSync opsync
    where opsync.uid = :uid and opsync.devId = :toDevId and opsync.opId = record.id
  ) and devId = :fromDevId
  order by case when module='App信息' then 1 else 0 end desc, id desc
  """)
  Future<List<OperationRecord>> getSyncRecord(int uid, String toDevId, String fromDevId);

  ///删除当前用户的所有操作记录
  @Query("delete from OperationRecord where uid = :uid")
  Future<int?> removeAll(int uid);

  ///根据 id 删除记录
  @Query("delete from OperationRecord where id in (:ids)")
  Future<int?> deleteByIds(List<int> ids);

  ///尝试根据 data id 删除记录，存储的data可能不一定是id
  @Query("delete from OperationRecord where id in (:ids)")
  Future<int?> deleteByDataIds(List<String> ids);

  @Query(
    "select * from OperationRecord where uid = :uid and module = :module and method = :opMethod and data = :id order by id desc limit 1",
  )
  Future<OperationRecord?> getByDataId(int id, String module, String opMethod, int uid);

  @Query("select * from OperationRecord where devId = :devId and storageSync = 1 order by id desc limit 1")
  Future<OperationRecord?> getLatestStorageSyncSuccessByDevId(String devId);

  /// 删除指定模块的同步记录
  @Query(
    "delete from OperationRecord where uid = :uid and module = :module",
  )
  Future<int?> removeByModule(String module, int uid);

  /// 删除指定模块的同步记录(Android 不支持 json_extract)
  @Query(
    r"delete from OperationRecord where uid = :uid and module = '规则设置' and substr(data,instr(data,':') + 2,instr(data,',') - 3 - instr(data,':')) = :rule",
  )
  Future<int?> removeRuleRecord(String rule, int uid);

  /// 删除指定设备的操作记录
  @Query("delete from OperationRecord where uid = :uid and devId in (:devIds)")
  Future<int?> removeByDevIds(int uid, List<String> devIds);

  /// 根据 data（主键）删除同步记录
  @Query(r"delete from OperationRecord where data = :data")
  Future<int?> deleteByData(String data);

  /// 根据 data（主键）获取操作记录
  @Query(r"select * from OperationRecord where data = :data")
  Future<List<OperationRecord>> getByData(String data);

  ///级联删除操作记录
  Future<void> deleteByDataWithCascade(String data) async {
    final storageService = Get.find<StorageService>();
    if (storageService.running) {
      try {
        //获取需要删除的操作记录
        final list = await getByData(data);
        //删除云端的
        storageService.deleteOpRecords(list);
      } catch (err, stack) {
        Log.error(tag, err, stack);
      }
    }
    //删除同步记录
    await dbService.opSyncDao.deleteByOpRecordData(data);
    //再删除操作记录
    await deleteByData(data);
  }

  @Query(r"delete from OperationRecord where data = :historyId and module = :moduleName")
  Future<void> deleteHistorySourceRecords(int historyId, String moduleName);

  @Query("select * from OperationRecord where id > :fromId order by id limit 1000 ")
  Future<List<OperationRecord>> getListLimit1000(int fromId);

  @Query("update OperationRecord set storageSync = :success where id = :id")
  Future<int?> updateStorageSyncStatus(int id, bool success);

  @Query("select * from OperationRecord where devId = :devId and storageSync = 0")
  Future<List<OperationRecord>> getStorageSyncFiledData(String devId);

  @Query("select * from OperationRecord where id = :id")
  Future<OperationRecord?> getById(int id);

  ///重新同步数据
  ///内容/标签/来源信息
  Future<void> resyncData(int historyId) async {
    final history = await dbService.historyDao.getById(historyId);
    if (history == null) {
      Log.warn(tag, "History is null: $historyId");
      return;
    }
    //历史记录
    var opRecord = OperationRecord.fromSimple(
      Module.history,
      OpMethod.add,
      historyId.toString(),
    );
    final result = await MissingDataSyncHandler.process(opRecord);
    await DataSender.sendData2All(MsgType.sync, result.result);
    //标签
    final tags = await dbService.historyTagDao.getAllByHisId(historyId);
    for (var tag in tags) {
      opRecord = OperationRecord.fromSimple(
        Module.tag,
        OpMethod.add,
        tag.id.toString(),
      );
      final result = await MissingDataSyncHandler.process(opRecord);
      await DataSender.sendData2All(MsgType.sync, result.result);
    }
    //来源信息
    if (history.source != null) {
      final devId = history.devId;
      final sourceService = Get.find<ClipboardSourceService>();
      final appInfo = sourceService.appInfos.where((item) => item.devId == devId && history.source == item.appId).firstOrNull;
      if (appInfo == null) {
        Log.warn(tag, "AppInfo is null source = ${history.source}");
        return;
      }
      opRecord = OperationRecord.fromSimple(
        Module.appInfo,
        OpMethod.add,
        appInfo.id,
      );
      final result = await MissingDataSyncHandler.process(opRecord);
      await DataSender.sendData2All(MsgType.sync, result.result);
    }
  }
}
