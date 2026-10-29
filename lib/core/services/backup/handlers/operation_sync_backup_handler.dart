import 'dart:io';
import 'dart:typed_data';

import 'package:clipshare/core/database/app_database.dart';
import 'package:clipshare/core/database/dao/operation_sync_dao.dart';
import 'package:clipshare/core/extensions/database_extension.dart';
import 'package:clipshare/core/services/backup/backup_type.dart';
import 'package:clipshare/core/services/backup/backup_version_info.dart';
import 'package:clipshare/core/services/backup/base_backup_handler.dart';
import 'package:clipshare/shared/utils/parallerl_task.dart';
import 'package:clipshare/shared/utils/snowflake.dart';
import 'package:msgpack_dart/msgpack_dart.dart' as m2;

/// 同步记录备份处理器
class OperationSyncBackupHandler with BaseBackupHandler {
  static const tag = 'OperationSyncBackupHandler';

  final AppDatabase _db;
  final Snowflake _snowflake;

  OperationSyncBackupHandler(this._db, this._snowflake);

  OperationSyncDao get _opSyncDao => _db.operationSyncDao;

  @override
  final BackupType backupType = BackupType.operationSync;

  @override
  Stream<Uint8List> loadData(Directory tempDir) async* {
    var list = await _opSyncDao.getAll();
    for (var item in list) {
      yield m2.serialize(item.toJson());
    }
  }

  @override
  Future<int> restore(Uint8List bytes, BackupVersionInfo version, Directory tempDir, CancelToken cancelToken, OnRestoreDone onDone) async {
    final map = m2.deserialize(bytes) as Map<dynamic, dynamic>;
    //旧备份包不含 time 字段，恢复时取当前时间
    final opSync = OperationSync(
      opId: map['opId'],
      devId: map['devId'],
      uid: map['uid'],
      time: map['time'] ?? DateTime.now().toString(),
    );
    final rid = _snowflake.nextId();
    _db.execSequentially(() {
      if (cancelToken.isCanceled) {
        return Future.value();
      }
      return _opSyncDao.add(opSync).whenComplete(() => onDone(rid));
    });
    return rid;
  }
}
