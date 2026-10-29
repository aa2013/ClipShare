// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'operation_record_dao.dart';

// ignore_for_file: type=lint
mixin _$OperationRecordDaoMixin on DatabaseAccessor<AppDatabase> {
  $OperationRecordsTable get operationRecords =>
      attachedDatabase.operationRecords;
  $OperationSyncsTable get operationSyncs => attachedDatabase.operationSyncs;
  OperationRecordDaoManager get managers => OperationRecordDaoManager(this);
}

class OperationRecordDaoManager {
  final _$OperationRecordDaoMixin _db;
  OperationRecordDaoManager(this._db);
  $$OperationRecordsTableTableManager get operationRecords =>
      $$OperationRecordsTableTableManager(
        _db.attachedDatabase,
        _db.operationRecords,
      );
  $$OperationSyncsTableTableManager get operationSyncs =>
      $$OperationSyncsTableTableManager(
        _db.attachedDatabase,
        _db.operationSyncs,
      );
}
