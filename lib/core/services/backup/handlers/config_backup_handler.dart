import 'dart:io';
import 'dart:typed_data';

import 'package:clipshare/core/database/app_database.dart';
import 'package:clipshare/core/database/dao/config_dao.dart';
import 'package:clipshare/core/extensions/database_extension.dart';
import 'package:clipshare/core/services/backup/backup_type.dart';
import 'package:clipshare/core/services/backup/backup_version_info.dart';
import 'package:clipshare/core/services/backup/base_backup_handler.dart';
import 'package:clipshare/shared/enums/config_key.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:clipshare/shared/utils/parallerl_task.dart';
import 'package:clipshare/shared/utils/snowflake.dart';
import 'package:msgpack_dart/msgpack_dart.dart' as m2;

/// 配置信息备份处理器
class ConfigBackupHandler with BaseBackupHandler {
  static const tag = 'ConfigBackupHandler';

  final AppDatabase _db;
  final Snowflake _snowflake;

  ConfigBackupHandler(this._db, this._snowflake);

  ConfigDao get _configDao => _db.configDao;

  @override
  final BackupType backupType = BackupType.config;

  @override
  Stream<Uint8List> loadData(Directory tempDir) async* {
    final configs = await _configDao.getAllConfigs();
    for (var config in configs) {
      yield m2.serialize(config.toJson());
    }
  }

  @override
  Future<int?> restore(Uint8List bytes, BackupVersionInfo version, Directory tempDir, CancelToken cancelToken, OnRestoreDone onDone) async {
    final map = m2.deserialize(bytes) as Map<dynamic, dynamic>;
    final config = Config.fromJson(map.cast<String, dynamic>());
    try {
      final rid = _snowflake.nextId();
      final key = ConfigKey.values.byName(config.key);
      _db.execSequentially(() {
        if (cancelToken.isCanceled) {
          return Future.value();
        }
        return _configDao.addOrUpdate(key, config.value).whenComplete(() => onDone(rid));
      });
      return rid;
    } catch (err, stack) {
      logger.error(tag, err, stack);
      return null;
    }
  }
}
