import 'dart:async';
import 'dart:io';

import 'package:clipshare/app/data/repository/dao/app_info_dao.dart';
import 'package:clipshare/app/data/repository/dao/config_dao.dart';
import 'package:clipshare/app/data/repository/dao/device_dao.dart';
import 'package:clipshare/app/data/repository/dao/history_dao.dart';
import 'package:clipshare/app/data/repository/dao/history_tag_dao.dart';
import 'package:clipshare/app/data/repository/dao/operation_record_dao.dart';
import 'package:clipshare/app/data/repository/dao/operation_sync_dao.dart';
import 'package:clipshare/app/data/repository/dao/user_dao.dart';
import 'package:clipshare/app/data/repository/entity/tables/app_info.dart';
import 'package:clipshare/app/data/repository/entity/tables/config.dart';
import 'package:clipshare/app/data/repository/entity/tables/device.dart';
import 'package:clipshare/app/data/repository/entity/tables/history.dart';
import 'package:clipshare/app/data/repository/entity/tables/history_tag.dart';
import 'package:clipshare/app/data/repository/entity/tables/operation_record.dart';
import 'package:clipshare/app/data/repository/entity/tables/operation_sync.dart';
import 'package:clipshare/app/data/repository/entity/tables/user.dart';
import 'package:clipshare/app/data/repository/entity/views/v_history_tag_hold.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/file_util.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:floor/floor.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

part 'package:clipshare/app/data/repository/db/app_db.floor.g.dart';

/// 添加实体类到 @Database 注解中，app_db、db_util 中添加 get 方法
/// 生成方法（二选一）
///
/// 1. 执行命令 flutter pub run build_runner build --delete-conflicting-outputs
///    生成的文件位于 .dart_tool/build/generated/项目名称/lib/db
///    下面这行放在 app_db.floor.g.dart 文件里，使其变成 app_database.dart 文件的一部分
///    part of 'app_db.dart';
///
/// 2. 直接执行 /scripts/db_gen.bat 一键完成
@Database(
  version: 5,
  entities: [
    Config,
    Device,
    History,
    User,
    OperationSync,
    HistoryTag,
    OperationRecord,
    AppInfo,
  ],
  views: [
    VHistoryTagHold,
  ],
)
abstract class _AppDb extends FloorDatabase {
  UserDao get userDao;

  ConfigDao get configDao;

  HistoryDao get historyDao;

  DeviceDao get deviceDao;

  OperationSyncDao get operationSyncDao;

  HistoryTagDao get historyTagDao;

  OperationRecordDao get operationRecordDao;

  AppInfoDao get appInfoDao;
}

class DbService extends GetxService {
  ///定义数据库变量
  late final _AppDb _db;

  ConfigDao get configDao => _db.configDao;

  HistoryDao get historyDao => _db.historyDao;

  DeviceDao get deviceDao => _db.deviceDao;

  UserDao get userDao => _db.userDao;

  OperationSyncDao get opSyncDao => _db.operationSyncDao;

  HistoryTagDao get historyTagDao => _db.historyTagDao;

  OperationRecordDao get opRecordDao => _db.operationRecordDao;

  AppInfoDao get appInfoDao => _db.appInfoDao;

  final tag = "DbService";

  late final int version;

  sqflite.DatabaseExecutor get dbExecutor => _db.database;
  Future _queue = Future.value();

  void execSequentially(Future Function() f) {
    _queue = _queue.whenComplete(() => f().catchError((err) => Log.error(tag, err)));
  }

  Future<DbService> init() async {
    // 获取应用程序的文件目录
    String databasesPath = "clipshare.db";
    if (Platform.isWindows) {
      var dirPath = Directory(Platform.resolvedExecutable).parent.path;
      if (!FileUtil.testWriteable(dirPath)) {
        dirPath = await Constants.documentsPath;
      }
      databasesPath = "$dirPath\\$databasesPath";
    }
    _db = await $Floor_AppDb.databaseBuilder(databasesPath).addMigrations([
      migration1to2,
      migration2to3,
      migration3to4,
      migration4to5,
    ]).build();
    version = await _db.database.database.getVersion();
    return this;
  }

  @override
  Future<void> onClose() {
    print("db service onClose");
    return _db.close();
  }

  ///----- 迁移策略 更新数据库版本后需要重新生成数据库代码 -----
  ///数据库版本 1 -> 2
  ///操作记录表新增设备id字段，用于从连接设备同步其他已配对设备数据
  final migration1to2 = Migration(1, 2, (database) async {
    await database.execute('ALTER TABLE OperationRecord ADD COLUMN devId TEXT');
  });

  ///数据库版本 2 -> 3
  ///操作同步表联合主键
  final migration2to3 = Migration(2, 3, (database) async {
    await database.execute('''
        CREATE TABLE OperationSyncNew (
          opId INTEGER NOT NULL,
          devId TEXT NOT NULL,
          uid INTEGER NOT NULL,
          time TEXT NOT NULL,
          PRIMARY KEY (opId, devId, uid)
        );
      ''');

    await database.execute('''
      INSERT INTO OperationSyncNew (opId, devId, uid, time)
      SELECT opId, devId, uid, time FROM OperationSync;
    ''');

    await database.execute('DROP TABLE OperationSync;');
    await database.execute(
      'ALTER TABLE OperationSyncNew RENAME TO OperationSync;',
    );
  });

  ///数据库版本 3 -> 4
  ///历史表增加更新时间字段
  final migration3to4 = Migration(3, 4, (database) async {
    await database.execute("ALTER TABLE `History` ADD COLUMN `updateTime` TEXT;");
  });

  ///数据库版本 4 -> 5
  ///新增 app 信息表
  ///历史表增加来源字段
  final migration4to5 = Migration(4, 5, (database) async {
    await database.execute("ALTER TABLE `History` ADD COLUMN `source` TEXT;");
    await database.execute("CREATE TABLE IF NOT EXISTS `AppInfo` (`id` INTEGER NOT NULL, `appId` TEXT NOT NULL, `devId` TEXT NOT NULL, `name` TEXT NOT NULL, `iconB64` TEXT NOT NULL, PRIMARY KEY (`id`));");
    await database.execute('CREATE UNIQUE INDEX IF NOT EXISTS `index_AppInfo_appId_devId` ON `AppInfo` (`appId`, `devId`);');
  });
}
