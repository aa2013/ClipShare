import 'dart:async';

import 'dart:io';

import 'dart:typed_data';

import 'package:clipshare/app/data/enums/backup_type.dart';
import 'package:clipshare/app/data/enums/config_key.dart';
import 'package:clipshare/app/data/models/BackupVersionInfo.dart';
import 'package:clipshare/app/data/repository/entity/tables/config.dart';
import 'package:clipshare/app/handlers/backup/backup_handler.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:get/get.dart';
import "package:msgpack_dart/msgpack_dart.dart" as m2;

class ConfigBackupHandler with BaseBackupHandler {
  static const tag = "ConfigBackupHandler";
  final appConfig = Get.find<ConfigService>();
  final dbService = Get.find<DbService>();
  final configDao = Get.find<DbService>().configDao;

  @override
  final BackupType backupType = BackupType.config;

  @override
  Stream<Uint8List> loadData(Directory tempDir) async* {
    final configs = await configDao.getAllConfigs(appConfig.userId);
    for (var config in configs) {
      yield m2.serialize(config.toJson());
    }
  }

  @override
  Future<int?> restore(Uint8List bytes, BackupVersionInfo version, Directory tempDir, RxBool cancel, OnRestoreDone onDone) async {
    final map = m2.deserialize(bytes) as Map<dynamic, dynamic>;
    final config = Config.fromJson(map.cast());
    try {
      final rid = appConfig.snowflake.nextId();
      final key = ConfigKey.values.byName(config.key);
      dbService.execSequentially(() {
        if (cancel.value) {
          return Future.value();
        }
        return configDao.addOrUpdate(key, config.value).whenComplete(() => onDone(rid));
      });
      return rid;
    } catch (err, stack) {
      Log.error(tag, err, stack);
      return null;
    }
  }
}
