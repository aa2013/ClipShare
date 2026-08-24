// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rule_dao.dart';

// ignore_for_file: type=lint
mixin _$RuleDaoMixin on DatabaseAccessor<AppDatabase> {
  $RulesTable get rules => attachedDatabase.rules;
  RuleDaoManager get managers => RuleDaoManager(this);
}

class RuleDaoManager {
  final _$RuleDaoMixin _db;
  RuleDaoManager(this._db);
  $$RulesTableTableManager get rules =>
      $$RulesTableTableManager(_db.attachedDatabase, _db.rules);
}
