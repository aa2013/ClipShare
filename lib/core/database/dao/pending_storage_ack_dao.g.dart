// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_storage_ack_dao.dart';

// ignore_for_file: type=lint
mixin _$PendingStorageAckDaoMixin on DatabaseAccessor<AppDatabase> {
  $PendingStorageAcksTable get pendingStorageAcks =>
      attachedDatabase.pendingStorageAcks;
  PendingStorageAckDaoManager get managers => PendingStorageAckDaoManager(this);
}

class PendingStorageAckDaoManager {
  final _$PendingStorageAckDaoMixin _db;
  PendingStorageAckDaoManager(this._db);
  $$PendingStorageAcksTableTableManager get pendingStorageAcks =>
      $$PendingStorageAcksTableTableManager(
        _db.attachedDatabase,
        _db.pendingStorageAcks,
      );
}
