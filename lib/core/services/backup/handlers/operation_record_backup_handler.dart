import 'dart:io';
import 'dart:typed_data';

import 'package:clipshare/core/database/app_database.dart';
import 'package:clipshare/core/database/dao/operation_record_dao.dart';
import 'package:clipshare/core/database/tables/operation_record.dart';
import 'package:clipshare/core/extensions/database_extension.dart';
import 'package:clipshare/core/services/backup/backup_type.dart';
import 'package:clipshare/core/services/backup/backup_version_info.dart';
import 'package:clipshare/core/services/backup/base_backup_handler.dart';
import 'package:clipshare/shared/utils/parallerl_task.dart';
import 'package:clipshare/shared/utils/snowflake.dart';
import 'package:msgpack_dart/msgpack_dart.dart' as m2;

/// 操作记录备份处理器
class OperationRecordBackupHandler with BaseBackupHandler {
  static const tag = 'OperationRecordBackupHandler';

  final AppDatabase _db;
  final Snowflake _snowflake;

  OperationRecordBackupHandler(this._db, this._snowflake);

  OperationRecordDao get _opRecordDao => _db.operationRecordDao;

  @override
  final BackupType backupType = BackupType.operationRecord;

  @override
  Stream<Uint8List> loadData(Directory tempDir) async* {
    int lastId = 0;
    while (true) {
      var list = await _opRecordDao.getListLimit1000(lastId);
      if (list.isEmpty) {
        break;
      }
      for (var item in list) {
        yield m2.serialize(item.toJson());
      }
      lastId = list.last.id;
    }
  }

  @override
  Future<int> restore(Uint8List bytes, BackupVersionInfo version, Directory tempDir, CancelToken cancelToken, OnRestoreDone onDone) async {
    final map = m2.deserialize(bytes) as Map<dynamic, dynamic>;
    final opRecord = operationRecordFromJson(map.cast<String, dynamic>());
    final rid = _snowflake.nextId();
    _db.execSequentially(() {
      if (cancelToken.isCanceled) {
        return Future.value();
      }
      return _opRecordDao.add(opRecord).whenComplete(() => onDone(rid));
    });
    return rid;
  }
}
