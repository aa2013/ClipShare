// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'config_dao.dart';

// ignore_for_file: type=lint
mixin _$ConfigDaoMixin on DatabaseAccessor<AppDatabase> {
  $ConfigsTable get configs => attachedDatabase.configs;
  ConfigDaoManager get managers => ConfigDaoManager(this);
}

class ConfigDaoManager {
  final _$ConfigDaoMixin _db;
  ConfigDaoManager(this._db);
  $$ConfigsTableTableManager get configs =>
      $$ConfigsTableTableManager(_db.attachedDatabase, _db.configs);
}
