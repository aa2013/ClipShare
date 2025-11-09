import 'dart:io';
import 'dart:typed_data';

import 'package:clipshare/app/data/enums/backup_type.dart';
import 'package:clipshare/app/data/models/BackupVersionInfo.dart';
import 'package:clipshare/app/data/repository/entity/tables/app_info.dart';
import 'package:clipshare/app/handlers/backup/backup_handler.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:get/get.dart';
import "package:msgpack_dart/msgpack_dart.dart" as m2;

class AppInfoBackupHandler with BaseBackupHandler {
  final dbService = Get.find<DbService>();
  final appInfoDao = Get.find<DbService>().appInfoDao;
  final appConfig = Get.find<ConfigService>();

  @override
  final BackupType backupType = BackupType.appInfo;

  @override
  Stream<Uint8List> loadData(Directory tempDir) async* {
    final appInfos = await appInfoDao.getAllAppInfos();
    for (var appInfo in appInfos) {
      yield m2.serialize(appInfo.toJson());
    }
  }

  @override
  Future<int> restore(Uint8List bytes, BackupVersionInfo version, Directory tempDir, RxBool cancel, OnRestoreDone onDone) async {
    final map = m2.deserialize(bytes) as Map<dynamic, dynamic>;
    final appInfo = AppInfo.fromJson(map.cast<String, dynamic>());
    final rid = appConfig.snowflake.nextId();
    dbService.execSequentially(() {
      if (cancel.value) {
        return Future.value();
      }
      return appInfoDao.addAppInfo(appInfo).whenComplete(() => onDone(rid));
    });
    return rid;
  }
}
