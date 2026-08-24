// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_tag_dao.dart';

// ignore_for_file: type=lint
mixin _$HistoryTagDaoMixin on DatabaseAccessor<AppDatabase> {
  $HistoryTagsTable get historyTags => attachedDatabase.historyTags;
  $HistoriesTable get histories => attachedDatabase.histories;
  HistoryTagDaoManager get managers => HistoryTagDaoManager(this);
}

class HistoryTagDaoManager {
  final _$HistoryTagDaoMixin _db;
  HistoryTagDaoManager(this._db);
  $$HistoryTagsTableTableManager get historyTags =>
      $$HistoryTagsTableTableManager(_db.attachedDatabase, _db.historyTags);
  $$HistoriesTableTableManager get histories =>
      $$HistoriesTableTableManager(_db.attachedDatabase, _db.histories);
}
