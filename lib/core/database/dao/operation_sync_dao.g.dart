// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'operation_sync_dao.dart';

// ignore_for_file: type=lint
mixin _$OperationSyncDaoMixin on DatabaseAccessor<AppDatabase> {
  $OperationSyncsTable get operationSyncs => attachedDatabase.operationSyncs;
  $OperationRecordsTable get operationRecords =>
      attachedDatabase.operationRecords;
  $HistoriesTable get histories => attachedDatabase.histories;
  OperationSyncDaoManager get managers => OperationSyncDaoManager(this);
}

class OperationSyncDaoManager {
  final _$OperationSyncDaoMixin _db;
  OperationSyncDaoManager(this._db);
  $$OperationSyncsTableTableManager get operationSyncs =>
      $$OperationSyncsTableTableManager(
        _db.attachedDatabase,
        _db.operationSyncs,
      );
  $$OperationRecordsTableTableManager get operationRecords =>
      $$OperationRecordsTableTableManager(
        _db.attachedDatabase,
        _db.operationRecords,
      );
  $$HistoriesTableTableManager get histories =>
      $$HistoriesTableTableManager(_db.attachedDatabase, _db.histories);
}
