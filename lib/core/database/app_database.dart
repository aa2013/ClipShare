import 'dart:io';

import 'package:clipshare/core/database/app_tables.dart';
import 'package:clipshare/core/database/dao/app_info_dao.dart';
import 'package:clipshare/core/database/dao/config_dao.dart';
import 'package:clipshare/core/database/dao/device_dao.dart';
import 'package:clipshare/core/database/dao/history_dao.dart';
import 'package:clipshare/core/database/dao/history_tag_dao.dart';
import 'package:clipshare/core/database/dao/operation_record_dao.dart';
import 'package:clipshare/core/database/dao/operation_sync_dao.dart';
import 'package:clipshare/core/database/dao/pending_storage_ack_dao.dart';
import 'package:clipshare/core/database/dao/rule_dao.dart';
import 'package:clipshare/core/database/dao/script_module_dao.dart';
import 'package:clipshare/core/database/dao/user_dao.dart';
import 'package:clipshare/shared/enums/rule/rule_script_language.dart';
import 'package:clipshare/shared/models/module.dart';
import 'package:clipshare/shared/models/op_method.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

part 'app_database.g.dart';

/// Drift 行对象 JSON 序列化器，确保项目枚举在 toJson/fromJson 中使用稳定字符串。
class AppDriftValueSerializer extends ValueSerializer {
  const AppDriftValueSerializer();

  static const _defaultSerializer = ValueSerializer.defaults();

  @override
  dynamic toJson<T>(T value) {
    if (value is Module) {
      return value.moduleName;
    }
    if (value is OpMethod) {
      return value.name;
    }
    if (value is RuleScriptLanguage) {
      return value.name;
    }
    return _defaultSerializer.toJson<T>(value);
  }

  @override
  T fromJson<T>(dynamic json) {
    if (T == Module) {
      return Module.getValue(json.toString()) as T;
    }
    if (T == OpMethod) {
      return OpMethod.getValue(json.toString()) as T;
    }
    if (T == RuleScriptLanguage) {
      return RuleScriptLanguage.getValue(json.toString()) as T;
    }
    return _defaultSerializer.fromJson<T>(json);
  }
}

@DriftDatabase(
  include: {'app_views.drift'},
  tables: [
    Configs,
    Devices,
    Histories,
    Users,
    OperationSyncs,
    HistoryTags,
    OperationRecords,
    AppInfos,
    Rules,
    ScriptModules,
    PendingStorageAcks,
  ],
  daos: [
    UserDao,
    ConfigDao,
    HistoryDao,
    DeviceDao,
    OperationSyncDao,
    HistoryTagDao,
    OperationRecordDao,
    AppInfoDao,
    RuleDao,
    ScriptModuleDao,
    PendingStorageAckDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor) {
    driftRuntimeOptions.defaultSerializer = const AppDriftValueSerializer();
  }

  /// 数据库 schema 当前版本为 v11，用于验证 History 新增字段的升级流程。
  @override
  int get schemaVersion => dbSchemaVersion;

  /// 打开指定物理数据库文件，保持用户自定义 databasePath 的行为。
  static Future<QueryExecutor> openFile(String dbPath) async {
    final file = File(dbPath);
    await file.parent.create(recursive: true);
    return NativeDatabase(file);
  }

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
      },
      onUpgrade: (m, from, to) async {
        //老版本迁移（dbVersion<=10）
        await _upgradeFromLegacySchema(from);
        if (from < 11) {
          //await m.addColumnIfNotExists(table, column);
        }
      },
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }

  //region floor 历史迁移脚本：v10及以前

  /// 旧数据库版本 1 到 10 的逐步迁移
  Future<void> _upgradeFromLegacySchema(int from) async {
    await _ensureHistoryDeviceColumn();
    if (from < 2 && !await hasColumn('OperationRecord', 'devId')) {
      await customStatement('ALTER TABLE OperationRecord ADD COLUMN devId TEXT');
    }
    if (from < 3) {
      await customStatement('''
        CREATE TABLE OperationSyncNew (
          opId INTEGER NOT NULL,
          devId TEXT NOT NULL,
          uid INTEGER NOT NULL,
          time TEXT NOT NULL,
          PRIMARY KEY (opId, devId, uid)
        )
      ''');
      await customStatement('''
        INSERT INTO OperationSyncNew (opId, devId, uid, time)
        SELECT opId, devId, uid, time FROM OperationSync
      ''');
      await customStatement('DROP TABLE OperationSync');
      await customStatement('ALTER TABLE OperationSyncNew RENAME TO OperationSync');
    }
    if (from < 4 && !await hasColumn('History', 'updateTime')) {
      await customStatement('ALTER TABLE `History` ADD COLUMN `updateTime` TEXT');
    }
    if (from < 5) {
      if (!await hasColumn('History', 'source')) {
        await customStatement('ALTER TABLE `History` ADD COLUMN `source` TEXT');
      }
      await customStatement(
        'CREATE TABLE IF NOT EXISTS `AppInfo` (`id` INTEGER NOT NULL, `appId` TEXT NOT NULL, `devId` TEXT NOT NULL, `name` TEXT NOT NULL, `iconB64` TEXT NOT NULL, PRIMARY KEY (`id`))',
      );
    }
    if (from < 6) {
      if (!await hasColumn('OperationRecord', 'storageSync')) {
        await customStatement('ALTER TABLE `OperationRecord` ADD COLUMN `storageSync` INTEGER');
      }
      await customStatement(r"""
        INSERT OR IGNORE INTO config (key, value,uid)
        SELECT 'forwardWay', 'server', 0
        WHERE EXISTS (
            SELECT 1 FROM config WHERE key = 'forwardServer'
        )
        AND NOT EXISTS (
            SELECT 1 FROM config WHERE key = 'forwardWay'
        )
      """);
    }
    if (from < 8 && !await hasColumn('Device', 'internalAddress')) {
      await customStatement('ALTER TABLE `Device` ADD COLUMN `internalAddress` TEXT');
    }
    if (from < 9) {
      if (!await hasColumn('History', 'extracted')) {
        await customStatement('ALTER TABLE `History` ADD COLUMN `extracted` TEXT');
      }
      if (!await hasColumn('OperationRecord', 'moduleEn')) {
        await customStatement('ALTER TABLE `OperationRecord` ADD COLUMN `moduleEn` TEXT');
      }
      await customStatement('''
        CREATE TABLE IF NOT EXISTS `Rule` (
          `id` INTEGER NOT NULL,
          `name` TEXT NOT NULL,
          `platforms` TEXT NOT NULL,
          `sources` TEXT NOT NULL,
          `trigger` TEXT NOT NULL,
          `type` TEXT NOT NULL,
          `regexWhiteBlackMode` TEXT,
          `regexMain` TEXT NOT NULL,
          `regexAllowExtractData` INTEGER NOT NULL,
          `regexExtractedContent` TEXT NOT NULL,
          `regexAllowAddTag` INTEGER NOT NULL,
          `regexTags` TEXT NOT NULL,
          `regexIsSyncDisabled` INTEGER NOT NULL,
          `regexIsFinalRule` INTEGER NOT NULL,
          `scriptLanguage` TEXT NOT NULL,
          `scriptContent` TEXT NOT NULL,
          `version` INTEGER NOT NULL,
          `enabled` INTEGER NOT NULL,
          `order` INTEGER NOT NULL,
          PRIMARY KEY (`id`)
        )
      ''');
      await customStatement('''
        CREATE TABLE IF NOT EXISTS `ScriptModule` (
          `moduleName` TEXT NOT NULL,
          `displayName` TEXT NOT NULL,
          `language` TEXT NOT NULL,
          `source` TEXT NOT NULL,
          `version` INTEGER NOT NULL,
          PRIMARY KEY (`moduleName`)
        )
      ''');
    }
    if (from < 10) {
      await customStatement('''
        CREATE TABLE IF NOT EXISTS `PendingStorageAck` (
          `opId` INTEGER NOT NULL,
          `targetDevId` TEXT NOT NULL,
          PRIMARY KEY (`opId`, `targetDevId`)
        )
      ''');
    }
  }

  /// 历史表早期库可能缺少设备字段，读取 Drift 最新结构前必须先补齐，旧数据用空设备兜底避免读取崩溃。
  Future<void> _ensureHistoryDeviceColumn() async {
    if (await _hasTable('History') && !await hasColumn('History', 'devId')) {
      await customStatement("ALTER TABLE `History` ADD COLUMN `devId` TEXT NOT NULL DEFAULT ''");
    }
  }

  /// 查询旧表是否存在，用于兼容用户从任意历史版本直接升级。
  Future<bool> _hasTable(String tableName) async {
    final result = await customSelect(
      "SELECT COUNT(*) AS cnt FROM sqlite_master WHERE type = 'table' AND name = ?",
      variables: [Variable.withString(tableName)],
    ).getSingle();
    return result.read<int>('cnt') > 0;
  }

  //endregion
}

extension AppDatabasex on GeneratedDatabase {
  /// 查询旧表字段是否存在，用于幂等执行历史 schema 迁移。
  Future<bool> hasColumn(String tableName, String columnName) async {
    final result = await customSelect(
      'SELECT COUNT(*) AS cnt FROM pragma_table_info(?) WHERE name = ?',
      variables: [Variable.withString(tableName), Variable.withString(columnName)],
    ).getSingle();
    return result.read<int>('cnt') > 0;
  }
}

extension Migratorx on Migrator {
  /// 查询旧表字段是否存在，用于幂等执行历史 schema 迁移。
  Future<void> addColumnIfNotExists(TableInfo table, GeneratedColumn column) async {
    final tableName = table.actualTableName;
    final columnName = column.name;

    if (!await database.hasColumn(tableName, columnName)) {
      await addColumn(table, column);
    }
  }
}
