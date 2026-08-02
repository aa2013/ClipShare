import 'dart:async';

import 'package:clipshare/app/data/repository/dao/app_info_dao.dart';
import 'package:clipshare/app/data/repository/dao/config_dao.dart';
import 'package:clipshare/app/data/repository/dao/device_dao.dart';
import 'package:clipshare/app/data/repository/dao/history_dao.dart';
import 'package:clipshare/app/data/repository/dao/history_tag_dao.dart';
import 'package:clipshare/app/data/repository/dao/operation_record_dao.dart';
import 'package:clipshare/app/data/repository/dao/operation_sync_dao.dart';
import 'package:clipshare/app/data/repository/dao/pending_storage_ack_dao.dart';
import 'package:clipshare/app/data/repository/dao/rule_dao.dart';
import 'package:clipshare/app/data/repository/dao/script_module_dao.dart';
import 'package:clipshare/app/data/repository/dao/user_dao.dart';
import 'package:clipshare/app/data/repository/db/app_database.dart';
import 'package:clipshare/app/data/repository/db/app_tables.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/utils/extensions/string_extension.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

const tables = [
  'Config',
  'Device',
  'History',
  'User',
  'OperationSync',
  'HistoryTag',
  'OperationRecord',
  'AppInfo',
  'Rule',
  'ScriptModule',
  'PendingStorageAck',
];
const views = [vHistoryTagHoldViewName];

class DbService extends GetxService {
  /// Drift 数据库实例，负责真实连接、迁移和 Repository 创建。
  late final AppDatabase _db;

  AppDatabase get database => _db;

  ConfigDao get configRepository => _db.configDao;

  HistoryDao get historyRepository => _db.historyDao;

  DeviceDao get deviceRepository => _db.deviceDao;

  UserDao get userRepository => _db.userDao;

  OperationSyncDao get operationSyncRepository => _db.operationSyncDao;

  HistoryTagDao get historyTagRepository => _db.historyTagDao;

  OperationRecordDao get operationRecordRepository => _db.operationRecordDao;

  AppInfoDao get clipboardSourceRepository => _db.appInfoDao;

  RuleDao get ruleRepository => _db.ruleDao;

  ScriptModuleDao get scriptModuleRepository => _db.scriptModuleDao;

  PendingStorageAckDao get pendingStorageAckRepository => _db.pendingStorageAckDao;

  /// todo 兼容旧调用点的过渡 getter，内部已经完全由 Drift Repository 承接。
  ConfigDao get configDao => configRepository;

  /// todo 兼容旧调用点的过渡 getter，后续可逐步替换为 [historyRepository]。
  HistoryDao get historyDao => historyRepository;

  /// todo 兼容旧调用点的过渡 getter，后续可逐步替换为 [deviceRepository]。
  DeviceDao get deviceDao => deviceRepository;

  /// todo 兼容已废弃用户表的旧调用点。
  UserDao get userDao => userRepository;

  /// todo 兼容旧调用点的过渡 getter，后续可逐步替换为 [operationSyncRepository]。
  OperationSyncDao get opSyncDao => operationSyncRepository;

  /// todo 兼容旧调用点的过渡 getter，后续可逐步替换为 [historyTagRepository]。
  HistoryTagDao get historyTagDao => historyTagRepository;

  /// todo 兼容旧调用点的过渡 getter，后续可逐步替换为 [operationRecordRepository]。
  OperationRecordDao get opRecordDao => operationRecordRepository;

  /// todo 兼容旧调用点的过渡 getter，后续可逐步替换为 [clipboardSourceRepository]。
  AppInfoDao get appInfoDao => clipboardSourceRepository;

  /// todo 兼容旧调用点的过渡 getter，后续可逐步替换为 [ruleRepository]。
  RuleDao get ruleDao => ruleRepository;

  /// todo 兼容旧调用点的过渡 getter，后续可逐步替换为 [scriptModuleRepository]。
  ScriptModuleDao get scriptModuleDao => scriptModuleRepository;

  /// todo 兼容旧调用点的过渡 getter，后续可逐步替换为 [pendingStorageAckRepository]。
  PendingStorageAckDao get pendingStorageAckDao => pendingStorageAckRepository;

  final tag = "DbService";

  late final int version;

  Future _queue = Future.value();

  void execSequentially(Future Function() f) {
    _queue = _queue.whenComplete(() => f().catchError((err) => logger.error(tag, err)));
  }

  Future<DbService> init() async {
    final appConfig = Get.find<ConfigService>();
    final dbPath = await _resolveDbPath(appConfig);
    _db = AppDatabase(AppDatabase.openFile(dbPath));
    final row = await _db.customSelect('PRAGMA user_version').getSingle();
    version = row.data.values.first as int? ?? dbSchemaVersion;
    return this;
  }

  /// 执行数据库编辑器输入的单条原始 SQL，并返回数据库返回的结果行。
  ///
  /// 直接使用 Drift 底层 executor，不预先识别 SQL 类型，因此查询、写入、
  /// DDL 以及带 RETURNING 子句的语句都沿用 SQLite executor 的原生行为。
  Future<List<Map<String, Object?>>> rawQuery(String sql) {
    return _db.executor.runSelect(sql, const []);
  }

  /// 解析数据库路径，自定义目录优先，否则沿用 sqflite 旧默认数据库目录。
  Future<String> _resolveDbPath(ConfigService appConfig) async {
    const dbFileName = "clipshare.db";
    if (appConfig.databasePath.isNotNullAndEmpty) {
      return "${appConfig.databasePath}/$dbFileName".normalizePath;
    }
    return sqflite.getDatabasesPath().then((path) => "$path/$dbFileName".normalizePath);
  }

  @override
  Future<void> onClose() {
    debugPrint("db service onClose");
    return _db.close();
  }
}
