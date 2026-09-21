import 'package:clipshare/core/database/app_database.dart';
import 'package:clipshare/core/database/app_tables.dart';
import 'package:drift/drift.dart';

part 'pending_storage_ack_dao.g.dart';

@DriftAccessor(tables: [PendingStorageAcks])
class PendingStorageAckDao extends DatabaseAccessor<AppDatabase> with _$PendingStorageAckDaoMixin {
  PendingStorageAckDao(super.attachedDatabase);

  /// 添加一条待发送的存储中转 ACK，主键冲突时保持幂等。
  Future<int> add(PendingStorageAck item) {
    return into(pendingStorageAcks).insert(
      PendingStorageAcksCompanion.insert(
        opId: item.opId,
        targetDevId: item.targetDevId,
      ),
      mode: InsertMode.insertOrIgnore,
    );
  }

  /// 删除一条已发送完成的待 ACK 记录。
  Future<int?> remove(PendingStorageAck item) {
    return removeByKey(item.opId, item.targetDevId);
  }

  /// 按目标设备查询待发送 ACK，用于收到该设备 online 后定向补发。
  Future<List<PendingStorageAck>> getByTargetDevId(String targetDevId) {
    return (select(pendingStorageAcks)..where((tbl) => tbl.targetDevId.equals(targetDevId))).get();
  }

  /// 精确删除一条待发送 ACK，避免同 opId 不同设备的记录被误删。
  Future<int?> removeByKey(int opId, String targetDevId) {
    return (delete(pendingStorageAcks)
          ..where((tbl) => tbl.opId.equals(opId) & tbl.targetDevId.equals(targetDevId)))
        .go();
  }
}
