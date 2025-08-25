import 'dart:io';
import 'dart:typed_data';

import 'package:clipshare/app/data/models/BackupVersionInfo.dart';
import 'package:clipshare/app/data/repository/entity/tables/app_info.dart';
import 'package:clipshare/app/handlers/backup/backup_handler.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:get/get.dart';
import "package:msgpack_dart/msgpack_dart.dart" as m2;

class AppInfoBackupHandler with BaseBackupHandler {
  final dbService = Get.find<DbService>();
  final appInfoDao = Get.find<DbService>().appInfoDao;

  static const String _name = "appInfo.bin";

  @override
  String get name => _name;

  @override
  Stream<Uint8List> loadData(Directory tempDir) async* {
    final appInfos = await appInfoDao.getAllAppInfos();
    for (var appInfo in appInfos) {
      yield m2.serialize(appInfo.toJson());
    }
  }

  @override
  Future<void> restore(Uint8List bytes, BackupVersionInfo version, Directory tempDir) async {
    final map = m2.deserialize(bytes) as Map<dynamic, dynamic>;
    final appInfo = AppInfo.fromJson(map.cast<String, dynamic>());
    dbService.execSequentially(() => appInfoDao.addAppInfo(appInfo));
  }
}
