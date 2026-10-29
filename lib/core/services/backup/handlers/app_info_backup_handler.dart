import 'dart:io';
import 'dart:typed_data';

import 'package:clipshare/core/database/app_database.dart';
import 'package:clipshare/core/database/dao/app_info_dao.dart';
import 'package:clipshare/core/extensions/database_extension.dart';
import 'package:clipshare/core/services/backup/backup_type.dart';
import 'package:clipshare/core/services/backup/backup_version_info.dart';
import 'package:clipshare/core/services/backup/base_backup_handler.dart';
import 'package:clipshare/shared/utils/parallerl_task.dart';
import 'package:clipshare/shared/utils/snowflake.dart';
import 'package:msgpack_dart/msgpack_dart.dart' as m2;

/// 剪贴板来源备份处理器
class AppInfoBackupHandler with BaseBackupHandler {
  final AppDatabase _db;
  final Snowflake _snowflake;

  AppInfoBackupHandler(this._db, this._snowflake);

  AppInfoDao get _appInfoDao => _db.appInfoDao;

  @override
  final BackupType backupType = BackupType.appInfo;

  @override
  Stream<Uint8List> loadData(Directory tempDir) async* {
    final appInfos = await _appInfoDao.getAllAppInfos();
    for (var appInfo in appInfos) {
      yield m2.serialize(appInfo.toJson());
    }
  }

  @override
  Future<int> restore(Uint8List bytes, BackupVersionInfo version, Directory tempDir, CancelToken cancelToken, OnRestoreDone onDone) async {
    final map = m2.deserialize(bytes) as Map<dynamic, dynamic>;
    final appInfo = AppInfo.fromJson(map.cast<String, dynamic>());
    final rid = _snowflake.nextId();
    _db.execSequentially(() {
      if (cancelToken.isCanceled) {
        return Future.value();
      }
      return _appInfoDao.addAppInfo(appInfo).whenComplete(() => onDone(rid));
    });
    return rid;
  }
}
