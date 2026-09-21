// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'script_module_dao.dart';

// ignore_for_file: type=lint
mixin _$ScriptModuleDaoMixin on DatabaseAccessor<AppDatabase> {
  $ScriptModulesTable get scriptModules => attachedDatabase.scriptModules;
  ScriptModuleDaoManager get managers => ScriptModuleDaoManager(this);
}

class ScriptModuleDaoManager {
  final _$ScriptModuleDaoMixin _db;
  ScriptModuleDaoManager(this._db);
  $$ScriptModulesTableTableManager get scriptModules =>
      $$ScriptModulesTableTableManager(_db.attachedDatabase, _db.scriptModules);
}
