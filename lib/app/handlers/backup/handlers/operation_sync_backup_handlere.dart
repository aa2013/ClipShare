import 'dart:io';
import 'dart:typed_data';

import 'package:clipshare/app/data/enums/backup_type.dart';
import 'package:clipshare/app/data/models/BackupVersionInfo.dart';
import 'package:clipshare/app/data/repository/entity/tables/operation_sync.dart';
import 'package:clipshare/app/handlers/backup/backup_handler.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:get/get.dart';
import "package:msgpack_dart/msgpack_dart.dart" as m2;

class OperationSyncBackupHandler with BaseBackupHandler {
  static const tag = "OperationSyncBackupHandler";
  final dbService = Get.find<DbService>();
  final opSyncDao = Get.find<DbService>().opSyncDao;
  final appConfig = Get.find<ConfigService>();

  @override
  final BackupType backupType = BackupType.operationSync;

  @override
  Stream<Uint8List> loadData(Directory tempDir) async* {
    var list = await opSyncDao.getAll();
    for (var item in list) {
      yield m2.serialize(item.toJson());
    }
  }

  @override
  Future<int> restore(Uint8List bytes, BackupVersionInfo version, Directory tempDir, RxBool cancel, OnRestoreDone onDone) async {
    final map = m2.deserialize(bytes) as Map<dynamic, dynamic>;
    final opSync = OperationSync.fromJson(map.cast<String, dynamic>());
    final rid = appConfig.snowflake.nextId();
    dbService.execSequentially(() {
      if (cancel.value) {
        return Future.value();
      }
      return opSyncDao.add(opSync).whenComplete(() => onDone(rid));
    });
    return rid;
  }
}
