import 'package:clipshare/core/database/app_database.dart';
import 'package:clipshare/core/database/app_tables.dart';
import 'package:drift/drift.dart';

part 'operation_sync_dao.g.dart';

@DriftAccessor(tables: [OperationSyncs, OperationRecords, Histories])
class OperationSyncDao extends DatabaseAccessor<AppDatabase> with _$OperationSyncDaoMixin {
  OperationSyncDao(super.attachedDatabase);

  /// 添加同步记录，联合主键冲突时保持幂等。
  Future<int> add(OperationSync syncHistory) {
    return into(operationSyncs).insert(
      OperationSyncsCompanion.insert(
        opId: syncHistory.opId,
        devId: syncHistory.devId,
        uid: syncHistory.uid,
        time: syncHistory.time,
      ),
      mode: InsertMode.insertOrIgnore,
    );
  }

  /// 删除当前用户的所有操作同步记录。
  Future<int?> removeAll(int uid) {
    return (delete(operationSyncs)..where((tbl) => tbl.uid.equals(uid))).go();
  }

  /// 按操作记录 id 批量删除当前用户同步记录。
  Future<int?> deleteByIds(int uid, List<int> ids) {
    if (ids.isEmpty) return Future.value(0);
    return (delete(operationSyncs)..where((tbl) => tbl.uid.equals(uid) & tbl.opId.isIn(ids))).go();
  }

  /// 删除指定设备的同步记录。
  Future<int?> deleteByDevIds(int uid, List<String> devIds) {
    if (devIds.isEmpty) return Future.value(0);
    return (delete(operationSyncs)..where((tbl) => tbl.uid.equals(uid) & tbl.devId.isIn(devIds))).go();
  }

  /// 重置设备所有历史记录为未同步。
  Future<int?> resetSyncStatus(String devId) {
    return (update(histories)..where((tbl) => tbl.devId.equals(devId))).write(
      const HistoriesCompanion(sync: Value(false)),
    );
  }

  /// 根据操作记录 data 删除其对应同步记录。
  Future<int?> deleteByOpRecordData(String opRecordData) async {
    final opIdsQuery = selectOnly(operationRecords)
      ..addColumns([operationRecords.id])
      ..where(operationRecords.data.equals(opRecordData));
    return (delete(operationSyncs)..where((tbl) => tbl.opId.isInQuery(opIdsQuery))).go();
  }

  /// 获取全部同步记录，主要用于备份和调试。
  Future<List<OperationSync>> getAll() {
    return select(operationSyncs).get();
  }
}
