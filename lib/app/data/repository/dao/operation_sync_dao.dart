import 'package:floor/floor.dart';

import '../entity/tables/operation_sync.dart';

@dao
abstract class OperationSyncDao {
  ///添加同步记录
  @Insert(onConflict: OnConflictStrategy.ignore)
  Future<int> add(OperationSync syncHistory);

  ///删除当前用户的所有操作同步记录
  @Query("delete OperationSync where uid = :uid")
  Future<int?> removeAll(int uid);

  ///删除当前用户的所有操作同步记录
  @Query("delete OperationSync where uid = :uid and opId in (:ids)")
  Future<int?> deleteByIds(int uid, List<int> ids);

  /// 删除指定设备的同步记录
  @Query(
    "delete from OperationSync where uid = :uid and devId in (:devIds)",
  )
  Future<int?> deleteByDevIds(int uid, List<String> devIds);

  ///重置设备所有记录为未同步
  @Query("update history set sync = 0 where devId = :devId")
  Future<int?> resetSyncStatus(String devId);

  ///根据操作记录数据删除同步记录
  @Query(
    "delete OperationSync where opId in (select id from OperationRecord where data = :opRecordData)",
  )
  Future<int?> deleteByOpRecordData(String opRecordData);

  @Query("select * from OperationSync")
  Future<List<OperationSync>> getAll();
}
