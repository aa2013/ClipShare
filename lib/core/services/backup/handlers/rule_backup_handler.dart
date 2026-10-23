import 'dart:io';
import 'dart:typed_data';

import 'package:clipshare/core/database/app_database.dart';
import 'package:clipshare/core/database/dao/rule_dao.dart';
import 'package:clipshare/core/database/tables/rule.dart';
import 'package:clipshare/core/extensions/database_extension.dart';
import 'package:clipshare/core/services/backup/backup_type.dart';
import 'package:clipshare/core/services/backup/backup_version_info.dart';
import 'package:clipshare/core/services/backup/base_backup_handler.dart';
import 'package:clipshare/shared/utils/parallerl_task.dart';
import 'package:clipshare/shared/utils/snowflake.dart';
import 'package:msgpack_dart/msgpack_dart.dart' as m2;

/// 规则备份处理器，载荷沿用同步协议的 language/content 字段名
class RuleBackupHandler with BaseBackupHandler {
  final AppDatabase _db;
  final Snowflake _snowflake;

  RuleBackupHandler(this._db, this._snowflake);

  RuleDao get _ruleDao => _db.ruleDao;

  @override
  final BackupType backupType = BackupType.rule;

  @override
  Stream<Uint8List> loadData(Directory tempDir) async* {
    final rules = await _ruleDao.getAllRules();
    for (var rule in rules) {
      yield m2.serialize(ruleToSyncPayload(rule));
    }
  }

  @override
  Future<int> restore(Uint8List bytes, BackupVersionInfo version, Directory tempDir, CancelToken cancelToken, OnRestoreDone onDone) async {
    final map = m2.deserialize(bytes) as Map<dynamic, dynamic>;
    final rule = ruleFromSyncJson(map.cast<String, dynamic>());
    final rid = _snowflake.nextId();
    _db.execSequentially(() {
      if (cancelToken.isCanceled) {
        return Future.value();
      }
      return _ruleDao.addRule(rule).whenComplete(() => onDone(rid));
    });
    return rid;
  }
}
