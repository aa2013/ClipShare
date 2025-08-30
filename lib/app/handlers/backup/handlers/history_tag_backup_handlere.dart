import 'dart:io';
import 'dart:typed_data';

import 'package:clipshare/app/data/models/BackupVersionInfo.dart';
import 'package:clipshare/app/data/repository/entity/tables/history_tag.dart';
import 'package:clipshare/app/handlers/backup/backup_handler.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:get/get.dart';
import "package:msgpack_dart/msgpack_dart.dart" as m2;

class HistoryTagBackupHandler with BaseBackupHandler {
  static const tag = "HistoryTagBackupHandler";
  final dbService = Get.find<DbService>();
  final historyTagDao = Get.find<DbService>().historyTagDao;
  final appConfig = Get.find<ConfigService>();

  static const String _name = "historyTag.bin";

  @override
  String get name => _name;

  @override
  Stream<Uint8List> loadData(Directory tempDir) async* {
    var list = await historyTagDao.getAll();
    for (var item in list) {
      yield m2.serialize(item.toJson());
    }
  }

  @override
  Future<int> restore(Uint8List bytes, BackupVersionInfo version, Directory tempDir, RxBool cancel, OnRestoreDone onDone) async {
    final map = m2.deserialize(bytes) as Map<dynamic, dynamic>;
    final historyTag = HistoryTag.fromJson(map.cast<String, dynamic>());
    final rid = appConfig.snowflake.nextId();
    dbService.execSequentially(() {
      if (cancel.value) {
        return Future.value();
      }
      return historyTagDao.add(historyTag).whenComplete(() => onDone(rid));
    });
    return rid;
  }
}
