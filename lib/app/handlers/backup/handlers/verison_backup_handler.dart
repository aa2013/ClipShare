import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:clipshare/app/data/models/BackupVersionInfo.dart';
import 'package:clipshare/app/handlers/backup/backup_handler.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:get/get.dart';

class VersionBackupHandler with BaseBackupHandler {
  final dbService = Get.find<DbService>();
  final appConfig = Get.find<ConfigService>();

  static const String _name = "version.json";

  @override
  String get name => _name;

  @override
  Stream<Uint8List> loadData(Directory tempDir) async* {
    final versionStr = BackupVersionInfo(
      dbService.version,
      appConfig.version.codeNum,
      appConfig.localName,
      appConfig.device.guid,
    ).toString();
    yield utf8.encode(versionStr);
  }

  @override
  int? restore(Uint8List bytes, BackupVersionInfo version, Directory tempDir, RxBool cancel, OnRestoreDone onDone) {
    throw 'not implement';
  }
}
