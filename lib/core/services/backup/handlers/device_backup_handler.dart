import 'dart:io';
import 'dart:typed_data';

import 'package:clipshare/core/database/app_database.dart';
import 'package:clipshare/core/database/dao/device_dao.dart';
import 'package:clipshare/core/database/tables/device.dart';
import 'package:clipshare/core/extensions/database_extension.dart';
import 'package:clipshare/core/services/backup/backup_type.dart';
import 'package:clipshare/core/services/backup/backup_version_info.dart';
import 'package:clipshare/core/services/backup/base_backup_handler.dart';
import 'package:clipshare/core/services/device/local_device_info.dart';
import 'package:clipshare/shared/utils/parallerl_task.dart';
import 'package:clipshare/shared/utils/snowflake.dart';
import 'package:msgpack_dart/msgpack_dart.dart' as m2;

/// 已配对设备信息备份处理器，本机设备始终作为首条写入备份
class DeviceBackupHandler with BaseBackupHandler {
  final AppDatabase _db;
  final LocalDeviceInfo _localDevInfo;
  final Snowflake _snowflake;

  DeviceBackupHandler(this._db, this._localDevInfo, this._snowflake);

  DeviceDao get _deviceDao => _db.deviceDao;

  @override
  final BackupType backupType = BackupType.device;

  @override
  Stream<Uint8List> loadData(Directory tempDir) async* {
    final myDev = _localDevInfo.self;
    final device = Device(guid: myDev.guid, devName: myDev.name, uid: 0, type: myDev.type, isPaired: false);
    yield m2.serialize(device.toJson());
    final devices = await _deviceDao.getAllDevices();
    for (var dev in devices) {
      yield m2.serialize(dev.toJson());
    }
  }

  @override
  Future<int?> restore(Uint8List bytes, BackupVersionInfo version, Directory tempDir, CancelToken cancelToken, OnRestoreDone onDone) async {
    final map = m2.deserialize(bytes) as Map<dynamic, dynamic>;
    final device = Device.fromJson(map.cast<String, dynamic>());
    final baseDevInfo = _localDevInfo.baseDeviceInfo;
    // 本机设备信息不通过备份恢复
    if (device.guid == baseDevInfo.guid) {
      return null;
    }
    final rid = _snowflake.nextId();
    _db.execSequentially(() {
      if (cancelToken.isCanceled) {
        return Future.value();
      }
      return _deviceDao.add(device).whenComplete(() => onDone(rid));
    });
    return rid;
  }
}
