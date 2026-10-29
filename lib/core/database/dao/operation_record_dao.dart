import 'package:clipshare/core/database/app_database.dart';
import 'package:clipshare/core/database/app_tables.dart';
import 'package:clipshare/shared/models/module.dart';
import 'package:clipshare/shared/models/op_method.dart';
import 'package:drift/drift.dart';

part 'operation_record_dao.g.dart';

@DriftAccessor(tables: [OperationRecords, OperationSyncs])
class OperationRecordDao extends DatabaseAccessor<AppDatabase> with _$OperationRecordDaoMixin {
  OperationRecordDao(super.attachedDatabase);

  static const tag = 'OperationRecordDao';

  /// 添加操作记录，主键冲突时保持旧 ignore 策略。
  Future<int> add(OperationRecord record) {
    return into(operationRecords).insert(
      _companion(record),
      mode: InsertMode.insertOrIgnore,
    );
  }

  /// 获取某设备的未同步记录，保留 SQLite 时间函数以兼容旧同步窗口逻辑。
  Future<List<OperationRecord>> getSyncRecord(
    String toDevId,
    String fromDevId,
    int syncOutdateLimitTimeSeconds,
    int timeZoneOffsetSeconds,
  ) {
    return customSelect(
      """
      select * from OperationRecord record
      where not exists (
        select 1 from OperationSync opsync
        where opsync.devId = ?1 and opsync.opId = record.id
      ) and devId = ?2
      and (
        ?3 <= 0
        or
        (strftime('%s', 'now') + ?4 - strftime('%s', record.time)) <= ?3
      )
      order by case when module='App信息' then 1 else 0 end desc, id desc
      """,
      variables: [
        Variable.withString(toDevId),
        Variable.withString(fromDevId),
        Variable.withInt(syncOutdateLimitTimeSeconds),
        Variable.withInt(timeZoneOffsetSeconds),
      ],
      readsFrom: {operationRecords, operationSyncs},
    ).map((row) => operationRecords.map(row.data)).get();
  }

  /// 删除所有操作记录。
  Future<int?> removeAll() {
    return delete(operationRecords).go();
  }

  /// 根据 id 批量删除记录。
  Future<int?> deleteByIds(List<int> ids) {
    if (ids.isEmpty) return Future.value(0);
    return (delete(operationRecords)..where((tbl) => tbl.id.isIn(ids))).go();
  }

  /// 尝试根据 data id 删除记录，旧方法参数为字符串列表但实际过滤 id 字段。
  Future<int?> deleteByDataIds(List<String> ids) {
    final parsedIds = ids.map(int.tryParse).whereType<int>().toList();
    if (parsedIds.isEmpty) return Future.value(0);
    return deleteByIds(parsedIds);
  }

  /// 查询某模块某方法中关联指定 data id 的最新操作记录。
  Future<OperationRecord?> getByDataId(int id, String module, String opMethod) {
    return (select(operationRecords)
          ..where(
            (tbl) => tbl.module.equalsValue(Module.getValue(module)) & tbl.method.equalsValue(OpMethod.getValue(opMethod)) & tbl.data.equals(id.toString()),
          )
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.id)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// 查询指定设备最近一次成功同步到存储服务的操作记录。
  Future<OperationRecord?> getLatestStorageSyncSuccessByDevId(String devId) {
    return (select(operationRecords)
          ..where((tbl) => tbl.devId.equals(devId) & tbl.storageSync.equals(true))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.id)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// 删除指定模块的同步记录。
  Future<int?> removeByModule(String module) {
    return (delete(operationRecords)..where((tbl) => tbl.module.equalsValue(Module.getValue(module)))).go();
  }

  /// 删除指定规则的操作记录，Android 旧实现不能依赖 json_extract，继续使用 substr 兼容。
  Future<int?> removeRuleRecord(String rule) {
    return customUpdate(
      r"delete from OperationRecord where module = '规则设置' and substr(data,instr(data,':') + 2,instr(data,',') - 3 - instr(data,':')) = ?1",
      variables: [
        Variable.withString(rule),
      ],
      updates: {operationRecords},
    );
  }

  /// 删除指定设备的操作记录。
  Future<int?> removeByDevIds(List<String> devIds) {
    if (devIds.isEmpty) return Future.value(0);
    return (delete(operationRecords)..where((tbl) => tbl.devId.isIn(devIds))).go();
  }

  /// 根据 data（主键）删除操作记录。
  Future<int?> deleteByData(String data) {
    return (delete(operationRecords)..where((tbl) => tbl.data.equals(data))).go();
  }

  /// 根据 data（主键）获取操作记录。
  Future<List<OperationRecord>> getByData(String data) {
    return (select(operationRecords)..where((tbl) => tbl.data.equals(data))).get();
  }

  /// 级联删除指定 data 的操作记录与同步记录，返回被删记录供服务层清理云端存储。
  Future<List<OperationRecord>> deleteByDataWithCascade(String data) async {
    final records = await getByData(data);
    await attachedDatabase.operationSyncDao.deleteByOpRecordData(data);
    await deleteByData(data);
    return records;
  }

  /// 删除指定历史来源变更操作记录。
  Future<void> deleteHistorySourceRecords(int historyId, String moduleName) async {
    await (delete(operationRecords)..where((tbl) => tbl.data.equals(historyId.toString()) & tbl.module.equalsValue(Module.getValue(moduleName)))).go();
  }

  /// 按 id 正序分页获取最多 1000 条操作记录。
  Future<List<OperationRecord>> getListLimit1000(int fromId) {
    return (select(operationRecords)
          ..where((tbl) => tbl.id.isBiggerThanValue(fromId))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.id)])
          ..limit(operationRecordPageSize))
        .get();
  }

  /// 更新存储服务同步状态。
  Future<int?> updateStorageSyncStatus(int id, bool success) {
    return (update(operationRecords)..where((tbl) => tbl.id.equals(id))).write(
      OperationRecordsCompanion(storageSync: Value(success)),
    );
  }

  /// 获取存储服务同步失败的数据。
  Future<List<OperationRecord>> getStorageSyncFiledData(String devId) {
    return (select(operationRecords)..where((tbl) => tbl.devId.equals(devId) & tbl.storageSync.equals(false))).get();
  }

  /// 根据操作记录主键查询。
  Future<OperationRecord?> getById(int id) {
    return (select(operationRecords)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  /// 将操作记录领域对象转换为 Drift 写入对象，显式保留旧雪花 id。
  OperationRecordsCompanion _companion(OperationRecord record) {
    return OperationRecordsCompanion.insert(
      id: Value(record.id),
      uid: record.uid,
      devId: record.devId,
      module: record.module,
      moduleEn: Value(record.moduleEn),
      method: record.method,
      data: record.data,
      time: record.time,
      storageSync: Value(record.storageSync),
    );
  }
}
