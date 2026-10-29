// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_info_dao.dart';

// ignore_for_file: type=lint
mixin _$AppInfoDaoMixin on DatabaseAccessor<AppDatabase> {
  $AppInfosTable get appInfos => attachedDatabase.appInfos;
  $HistoriesTable get histories => attachedDatabase.histories;
  AppInfoDaoManager get managers => AppInfoDaoManager(this);
}

class AppInfoDaoManager {
  final _$AppInfoDaoMixin _db;
  AppInfoDaoManager(this._db);
  $$AppInfosTableTableManager get appInfos =>
      $$AppInfosTableTableManager(_db.attachedDatabase, _db.appInfos);
  $$HistoriesTableTableManager get histories =>
      $$HistoriesTableTableManager(_db.attachedDatabase, _db.histories);
}
