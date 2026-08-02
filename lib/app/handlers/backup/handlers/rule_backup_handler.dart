import 'dart:io';
import 'dart:typed_data';

import 'package:clipshare/app/data/enums/backup_type.dart';
import 'package:clipshare/app/data/models/BackupVersionInfo.dart';
import 'package:clipshare/app/data/repository/entity/tables/app_info.dart';
import 'package:clipshare/app/data/repository/entity/tables/rule.dart';
import 'package:clipshare/app/handlers/backup/backup_handler.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:get/get.dart';
import "package:msgpack_dart/msgpack_dart.dart" as m2;

class RuleBackupHandler with BaseBackupHandler {
  final dbService = Get.find<DbService>();
  final ruleDao = Get.find<DbService>().ruleDao;
  final appConfig = Get.find<ConfigService>();

  @override
  final BackupType backupType = BackupType.rule;

  @override
  Stream<Uint8List> loadData(Directory tempDir) async* {
    final rules = await ruleDao.getAllRules();
    for (var rule in rules) {
      yield m2.serialize(rule.toJson());
    }
  }

  @override
  Future<int> restore(Uint8List bytes, BackupVersionInfo version, Directory tempDir, RxBool cancel, OnRestoreDone onDone) async {
    final map = m2.deserialize(bytes) as Map<dynamic, dynamic>;
    final rule = ruleFromJson(map.cast<String, dynamic>());
    final rid = appConfig.snowflake.nextId();
    dbService.execSequentially(() {
      if (cancel.value) {
        return Future.value();
      }
      return ruleDao.addRule(rule).whenComplete(() => onDone(rid));
    });
    return rid;
  }
}
