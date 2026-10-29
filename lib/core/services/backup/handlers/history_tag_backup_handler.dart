import 'dart:io';
import 'dart:typed_data';

import 'package:clipshare/core/database/app_database.dart';
import 'package:clipshare/core/database/dao/history_tag_dao.dart';
import 'package:clipshare/core/extensions/database_extension.dart';
import 'package:clipshare/core/services/backup/backup_type.dart';
import 'package:clipshare/core/services/backup/backup_version_info.dart';
import 'package:clipshare/core/services/backup/base_backup_handler.dart';
import 'package:clipshare/shared/utils/parallerl_task.dart';
import 'package:clipshare/shared/utils/snowflake.dart';
import 'package:msgpack_dart/msgpack_dart.dart' as m2;

/// 历史记录标签备份处理器
class HistoryTagBackupHandler with BaseBackupHandler {
  static const tag = 'HistoryTagBackupHandler';

  final AppDatabase _db;
  final Snowflake _snowflake;

  HistoryTagBackupHandler(this._db, this._snowflake);

  HistoryTagDao get _historyTagDao => _db.historyTagDao;

  @override
  final BackupType backupType = BackupType.historyTag;

  @override
  Stream<Uint8List> loadData(Directory tempDir) async* {
    var list = await _historyTagDao.getAll();
    for (var item in list) {
      yield m2.serialize(item.toJson());
    }
  }

  @override
  Future<int> restore(Uint8List bytes, BackupVersionInfo version, Directory tempDir, CancelToken cancelToken, OnRestoreDone onDone) async {
    final map = m2.deserialize(bytes) as Map<dynamic, dynamic>;
    final historyTag = HistoryTag.fromJson(map.cast<String, dynamic>());
    final rid = _snowflake.nextId();
    _db.execSequentially(() {
      if (cancelToken.isCanceled) {
        return Future.value();
      }
      return _historyTagDao.add(historyTag).whenComplete(() => onDone(rid));
    });
    return rid;
  }
}
