import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:clipshare/core/database/app_database.dart';
import 'package:clipshare/core/services/backup/backup_type.dart';
import 'package:clipshare/core/services/backup/backup_version_info.dart';
import 'package:clipshare/core/services/backup/base_backup_handler.dart';
import 'package:clipshare/core/services/device/local_device_info.dart';
import 'package:clipshare/shared/utils/parallerl_task.dart';

/// 版本信息备份处理器，内容写入备份包内的 version.json
class VersionBackupHandler with BaseBackupHandler {
  final AppDatabase _db;
  final LocalDeviceInfo _localDevInfo;

  VersionBackupHandler(this._db, this._localDevInfo);

  @override
  final BackupType backupType = BackupType.version;

  @override
  Stream<Uint8List> loadData(Directory tempDir) async* {
    final appVersion = _localDevInfo.appVersion;
    final baseDevInfo = _localDevInfo.baseDeviceInfo;
    final versionStr = BackupVersionInfo(
      _db.schemaVersion,
      appVersion.codeNum,
      _localDevInfo.localName,
      baseDevInfo.guid,
    ).toString();
    yield utf8.encode(versionStr);
  }

  @override
  int? restore(Uint8List bytes, BackupVersionInfo version, Directory tempDir, CancelToken cancelToken, OnRestoreDone onDone) {
    throw 'not implement';
  }
}
