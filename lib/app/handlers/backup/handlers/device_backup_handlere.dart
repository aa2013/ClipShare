import 'dart:io';
import 'dart:typed_data';

import 'package:clipshare/app/data/models/BackupVersionInfo.dart';
import 'package:clipshare/app/data/repository/entity/tables/device.dart';
import 'package:clipshare/app/handlers/backup/backup_handler.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:get/get.dart';
import "package:msgpack_dart/msgpack_dart.dart" as m2;

class DeviceBackupHandler with BaseBackupHandler {
  final dbService = Get.find<DbService>();
  final deviceDao = Get.find<DbService>().deviceDao;
  final appConfig = Get.find<ConfigService>();

  static const String _name = "device.bin";

  @override
  String get name => _name;

  @override
  Stream<Uint8List> loadData(Directory tempDir) async* {
    final myDev = appConfig.devInfo;
    final device = Device(guid: myDev.guid, devName: myDev.name, uid: 0, type: myDev.type);
    yield m2.serialize(device.toJson());
    final devices = await deviceDao.getAllDevices(appConfig.userId);
    for (var dev in devices) {
      yield m2.serialize(dev.toJson());
    }
  }

  @override
  Future<int?> restore(Uint8List bytes, BackupVersionInfo version, Directory tempDir, RxBool cancel, OnRestoreDone onDone) async {
    final map = m2.deserialize(bytes) as Map<dynamic, dynamic>;
    final device = Device.fromJson(map.cast<String, dynamic>());
    if (device.guid == appConfig.device.guid) {
      return null;
    }
    final rid = appConfig.snowflake.nextId();
    dbService.execSequentially(() {
      if (cancel.value) {
        return Future.value();
      }
      return deviceDao.add(device).whenComplete(() => onDone(rid));
    });
    return rid;
  }
}
