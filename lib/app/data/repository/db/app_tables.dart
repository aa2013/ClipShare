import 'package:clipshare/app/data/enums/module.dart';
import 'package:clipshare/app/data/enums/op_method.dart';
import 'package:clipshare/app/data/enums/rule/rule_script_language.dart';
import 'package:drift/drift.dart';

/// 数据库物理结构版本
const int dbSchemaVersion = 10;

/// 历史列表和清理页的默认分页大小。
const int historyPageSize = 100;

/// 操作记录批量同步的默认分页大小。
const int operationRecordPageSize = 1000;

/// 历史标签持有状态视图名
const String vHistoryTagHoldViewName = 'VHistoryTagHold';

@DataClassName('Config')
class Configs extends Table {
  @override
  String get tableName => 'Config';

  TextColumn get key => text()();

  TextColumn get value => text()();

  IntColumn get uid => integer()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

@DataClassName('Device')
class Devices extends Table {
  @override
  String get tableName => 'Device';

  TextColumn get guid => text()();

  TextColumn get devName => text().named('devName')();

  IntColumn get uid => integer()();

  TextColumn get customName => text().named('customName').nullable()();

  TextColumn get type => text()();

  TextColumn get address => text().nullable()();

  TextColumn get internalAddress => text().named('internalAddress').nullable()();

  BoolColumn get isPaired => boolean().named('isPaired')();

  @override
  Set<Column<Object>> get primaryKey => {guid};
}

@DataClassName('History')
@TableIndex(name: 'index_History_devId', columns: {#devId})
@TableIndex(name: 'index_History_devId_source', columns: {#devId, #source})
class Histories extends Table {
  @override
  String get tableName => 'History';

  IntColumn get id => integer()();

  IntColumn get uid => integer()();

  TextColumn get time => text()();

  TextColumn get content => text()();

  TextColumn get extracted => text().nullable()();

  TextColumn get type => text()();

  TextColumn get devId => text().named('devId')();

  BoolColumn get top => boolean()();

  BoolColumn get sync => boolean()();

  IntColumn get size => integer()();

  TextColumn get updateTime => text().named('updateTime').nullable()();

  TextColumn get source => text().nullable()();

  /// 历史记录使用业务侧分配的 id 作为主键，不启用自增。
  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('User')
@Deprecated("no longer use")
class Users extends Table {
  @override
  String get tableName => 'User';

  IntColumn get id => integer().nullable()();

  TextColumn get account => text()();

  TextColumn get password => text()();

  TextColumn get type => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('OperationSync')
class OperationSyncs extends Table {
  @override
  String get tableName => 'OperationSync';

  IntColumn get opId => integer().named('opId')();

  TextColumn get devId => text().named('devId')();

  IntColumn get uid => integer()();

  TextColumn get time => text()();

  @override
  Set<Column<Object>> get primaryKey => {opId, devId, uid};
}

@DataClassName('HistoryTag')
@TableIndex(name: 'index_HistoryTag_tagName_hisId', columns: {#tagName, #hisId}, unique: true)
class HistoryTags extends Table {
  @override
  String get tableName => 'HistoryTag';

  IntColumn get id => integer()();

  TextColumn get tagName => text().named('tagName')();

  IntColumn get hisId => integer().named('hisId')();

  /// 标签记录使用业务侧分配的 id 作为主键，不启用自增。
  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('OperationRecord')
@TableIndex(name: 'index_OperationRecord_uid_module_method', columns: {#uid, #module, #method})
@TableIndex(name: 'index_OperationRecord_moduleEn_method', columns: {#moduleEn, #method})
class OperationRecords extends Table {
  @override
  String get tableName => 'OperationRecord';

  IntColumn get id => integer()();

  IntColumn get uid => integer()();

  TextColumn get devId => text().named('devId')();

  TextColumn get module => text().map(const ModuleTypeConverter())();

  TextColumn get moduleEn => text().named('moduleEn').nullable()();

  TextColumn get method => text().map(const OpMethodTypeConverter())();

  TextColumn get data => text()();

  TextColumn get time => text()();

  BoolColumn get storageSync => boolean().named('storageSync').nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('AppInfo')
@TableIndex(name: 'index_AppInfo_appId_devId', columns: {#appId, #devId}, unique: true)
class AppInfos extends Table {
  @override
  String get tableName => 'AppInfo';

  IntColumn get id => integer()();

  TextColumn get appId => text().named('appId')();

  TextColumn get devId => text().named('devId')();

  TextColumn get name => text()();

  TextColumn get iconB64 => text().named('iconB64')();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('Rule')
class Rules extends Table {
  @override
  String get tableName => 'Rule';

  IntColumn get id => integer()();

  TextColumn get name => text()();

  TextColumn get platforms => text()();

  TextColumn get sources => text()();

  TextColumn get trigger => text()();

  TextColumn get type => text()();

  TextColumn get regexWhiteBlackMode => text().named('regexWhiteBlackMode').nullable()();

  TextColumn get regexMain => text().named('regexMain')();

  BoolColumn get regexAllowExtractData => boolean().named('regexAllowExtractData')();

  TextColumn get regexExtractedContent => text().named('regexExtractedContent')();

  BoolColumn get regexAllowAddTag => boolean().named('regexAllowAddTag')();

  TextColumn get regexTags => text().named('regexTags')();

  BoolColumn get regexIsSyncDisabled => boolean().named('regexIsSyncDisabled')();

  BoolColumn get regexIsFinalRule => boolean().named('regexIsFinalRule')();

  TextColumn get scriptLanguage => text().named('scriptLanguage')();

  TextColumn get scriptContent => text().named('scriptContent')();

  IntColumn get version => integer()();

  BoolColumn get enabled => boolean()();

  IntColumn get order => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ScriptModule')
class ScriptModules extends Table {
  @override
  String get tableName => 'ScriptModule';

  TextColumn get moduleName => text().named('moduleName')();

  TextColumn get displayName => text().named('displayName')();

  TextColumn get language => text().map(const RuleScriptLanguageConverter())();

  TextColumn get source => text()();

  IntColumn get version => integer()();

  @override
  Set<Column<Object>> get primaryKey => {moduleName};
}

@DataClassName('PendingStorageAck')
class PendingStorageAcks extends Table {
  @override
  String get tableName => 'PendingStorageAck';

  IntColumn get opId => integer().named('opId')();

  TextColumn get targetDevId => text().named('targetDevId')();

  @override
  Set<Column<Object>> get primaryKey => {opId, targetDevId};
}

/// 操作方法枚举到旧 TEXT 字段的转换器。
class OpMethodTypeConverter extends TypeConverter<OpMethod, String> {
  const OpMethodTypeConverter();

  @override
  OpMethod fromSql(String fromDb) {
    return OpMethod.getValue(fromDb);
  }

  @override
  String toSql(OpMethod value) {
    return value.name;
  }
}

/// 操作模块枚举到旧 TEXT 字段的转换器。
class ModuleTypeConverter extends TypeConverter<Module, String> {
  const ModuleTypeConverter();

  @override
  Module fromSql(String fromDb) {
    return Module.getValue(fromDb);
  }

  @override
  String toSql(Module value) {
    return value.moduleName;
  }
}

/// 脚本语言枚举到旧 TEXT 字段的转换器。
class RuleScriptLanguageConverter extends TypeConverter<RuleScriptLanguage, String> {
  const RuleScriptLanguageConverter();

  @override
  RuleScriptLanguage fromSql(String fromDb) {
    return RuleScriptLanguage.getValue(fromDb);
  }

  @override
  String toSql(RuleScriptLanguage value) {
    return value.name;
  }
}
