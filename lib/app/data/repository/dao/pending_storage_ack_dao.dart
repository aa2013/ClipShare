import 'package:clipshare/app/data/repository/entity/tables/pending_storage_ack.dart';
import 'package:floor/floor.dart';

@dao
abstract class PendingStorageAckDao {
  /// 添加一条待发送的存储中转 ACK，联合主键保证重复入队时保持幂等。
  @Insert(onConflict: OnConflictStrategy.ignore)
  Future<int> add(PendingStorageAck item);

  /// 删除一条已发送完成的待 ACK 记录。
  @delete
  Future<int?> remove(PendingStorageAck item);

  /// 按目标设备查询待发送 ACK，用于收到该设备 online 后定向补发。
  @Query("select * from PendingStorageAck where targetDevId = :targetDevId")
  Future<List<PendingStorageAck>> getByTargetDevId(String targetDevId);

  /// 精确删除一条待发送 ACK，避免同 opId 不同设备的记录被误删。
  @Query("delete from PendingStorageAck where opId = :opId and targetDevId = :targetDevId")
  Future<int?> removeByKey(int opId, String targetDevId);

}
