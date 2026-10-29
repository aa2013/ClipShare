import 'dart:io';
import 'dart:typed_data';

import 'package:clipshare/core/database/app_database.dart';
import 'package:clipshare/core/database/dao/script_module_dao.dart';
import 'package:clipshare/core/database/tables/script_module.dart';
import 'package:clipshare/core/extensions/database_extension.dart';
import 'package:clipshare/core/services/backup/backup_type.dart';
import 'package:clipshare/core/services/backup/backup_version_info.dart';
import 'package:clipshare/core/services/backup/base_backup_handler.dart';
import 'package:clipshare/shared/utils/parallerl_task.dart';
import 'package:clipshare/shared/utils/snowflake.dart';
import 'package:msgpack_dart/msgpack_dart.dart' as m2;

/// 脚本模块备份处理器
class ScriptModuleBackupHandler with BaseBackupHandler {
  final AppDatabase _db;
  final Snowflake _snowflake;

  ScriptModuleBackupHandler(this._db, this._snowflake);

  ScriptModuleDao get _scriptModuleDao => _db.scriptModuleDao;

  @override
  final BackupType backupType = BackupType.scriptModule;

  @override
  Stream<Uint8List> loadData(Directory tempDir) async* {
    final modules = await _scriptModuleDao.getAllModules();
    for (var module in modules) {
      yield m2.serialize(module.toJson());
    }
  }

  @override
  Future<int> restore(Uint8List bytes, BackupVersionInfo version, Directory tempDir, CancelToken cancelToken, OnRestoreDone onDone) async {
    final map = m2.deserialize(bytes) as Map<dynamic, dynamic>;
    final module = scriptModuleFromJson(map.cast<String, dynamic>());
    final rid = _snowflake.nextId();
    _db.execSequentially(() {
      if (cancelToken.isCanceled) {
        return Future.value();
      }
      return _scriptModuleDao.addModule(module).whenComplete(() => onDone(rid));
    });
    return rid;
  }
}
