import 'dart:io';
import 'dart:typed_data';

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

  static const String _name = "operationSync.bin";

  @override
  String get name => _name;

  @override
  Stream<Uint8List> loadData(Directory tempDir) async* {
    var list = await opSyncDao.getAll();
    for (var item in list) {
      yield m2.serialize(item.toJson());
    }
  }

  @override
  Future<void> restore(Uint8List bytes, BackupVersionInfo version, Directory tempDir) async {
    final map = m2.deserialize(bytes) as Map<dynamic, dynamic>;
    final opSync = OperationSync.fromJson(map.cast<String, dynamic>());
    dbService.execSequentially(() => opSyncDao.add(opSync));
  }
}
