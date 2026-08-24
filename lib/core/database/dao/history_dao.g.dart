// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_dao.dart';

// ignore_for_file: type=lint
mixin _$HistoryDaoMixin on DatabaseAccessor<AppDatabase> {
  $HistoriesTable get histories => attachedDatabase.histories;
  $HistoryTagsTable get historyTags => attachedDatabase.historyTags;
  $DevicesTable get devices => attachedDatabase.devices;
  HistoryDaoManager get managers => HistoryDaoManager(this);
}

class HistoryDaoManager {
  final _$HistoryDaoMixin _db;
  HistoryDaoManager(this._db);
  $$HistoriesTableTableManager get histories =>
      $$HistoriesTableTableManager(_db.attachedDatabase, _db.histories);
  $$HistoryTagsTableTableManager get historyTags =>
      $$HistoryTagsTableTableManager(_db.attachedDatabase, _db.historyTags);
  $$DevicesTableTableManager get devices =>
      $$DevicesTableTableManager(_db.attachedDatabase, _db.devices);
}
