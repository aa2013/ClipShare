import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:clipshare/app/data/models/BackupVersionInfo.dart';
import 'package:clipshare/app/data/models/exception_info.dart';
import 'package:clipshare/app/exceptions/user_cancel_backup.dart';
import 'package:clipshare/app/handlers/backup/backup_data_packet_splitter.dart';
import 'package:clipshare/app/handlers/backup/handlers/app_info_backup_handler.dart';
import 'package:clipshare/app/handlers/backup/handlers/config_backup_handler.dart';
import 'package:clipshare/app/handlers/backup/handlers/device_backup_handlere.dart';
import 'package:clipshare/app/handlers/backup/handlers/history_backup_handlere.dart';
import 'package:clipshare/app/handlers/backup/handlers/history_tag_backup_handlere.dart';
import 'package:clipshare/app/handlers/backup/handlers/operation_record_backup_handlere.dart';
import 'package:clipshare/app/handlers/backup/handlers/operation_sync_backup_handlere.dart';
import 'package:clipshare/app/handlers/backup/handlers/verison_backup_handler.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/utils/extensions/string_extension.dart';
import 'package:clipshare/app/utils/extensions/time_extension.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:clipshare/app/widgets/loading.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:zip_flutter/zip_flutter.dart';

typedef OnRestoreDone = void Function(int restoreid);

abstract mixin class BaseBackupHandler {
  String get name;

  ///load from db
  Stream<Uint8List> loadData(Directory tempDir);

  ///read data from backup and restore
  FutureOr<int?> restore(Uint8List bytes, BackupVersionInfo version, Directory tempDir,RxBool cancel, OnRestoreDone onDone);
}

class BackupHandler {
  BackupHandler._private();

  static const tag = 'BackupHandler';
  static BackupHandler instance = BackupHandler._private();
  static final Set<int> _restoreIds = {};
  final List<BaseBackupHandler> _handlers = [
    VersionBackupHandler(),
    ConfigBackupHandler(),
    AppInfoBackupHandler(),
    DeviceBackupHandler(),
    HistoryBackupHandler(),
    HistoryTagBackupHandler(),
    OperationRecordBackupHandler(),
    OperationSyncBackupHandler(),
  ];

  final dbService = Get.find<DbService>();
  final appConfig = Get.find<ConfigService>();
  bool _processing = false;
  final _cancel = false.obs;
  static const _endian = Endian.little;
  static const _headerLen = 4;

  void cancel() {
    _cancel.value = true;
  }

  void _testCancel() {
    if (_cancel.value) {
      throw UserCancelBackup();
    }
  }

  Future<ExceptionInfo?> backup(Directory storeDir) async {
    _restoreIds.clear();
    await storeDir.create(recursive: true);
    final tempDir = await storeDir.createTemp("temp_");
    if (_processing) {
      throw 'Backup or Restore processing';
    }
    _processing = true;
    _cancel.value = false;
    dynamic catchErr;
    StackTrace? stackTrace;
    try {
      for (var handler in _handlers) {
        final name = handler.name;
        _testCancel();
        final file = File("${tempDir.path}/$name".normalizePath);
        final writer = file.openWrite();
        Log.info(tag, "Start backup $name...");
        await for (var bytes in handler.loadData(tempDir)) {
          try {
            _testCancel();
          } catch (err) {
            writer.close();
            rethrow;
          }
          if (handler is! VersionBackupHandler) {
            final prefixLen = Uint8List(_headerLen);
            final byteData = prefixLen.buffer.asByteData();
            byteData.setUint32(0, bytes.length, _endian);
            writer.add(prefixLen);
          }
          writer.add(bytes);
        }
        await writer.close();
        Log.info(tag, "backup $name finished");
      }
      final backupFileName = "backup-${appConfig.localName}-${DateTime.now().format("yyyyMMdd")}.zip";
      var zip = ZipFile.open('${storeDir.path}/$backupFileName');
      await for (final entity in tempDir.list(recursive: true)) {
        if (entity is! File) {
          continue;
        }
        final file = entity;
        final data = await entity.readAsBytes();
        final relativePath = file.path.substring(tempDir.path.length + 1);
        zip.addFileFromBytes(relativePath, data);
      }
      zip.close();
      Log.info(tag, "backup all finished!!!");
    } catch (err, stack) {
      catchErr = err;
      stackTrace = stack;
      Log.debug(tag, "backup failed! Error: $err,$stack");
    } finally {
      _processing = false;
      _cancel.value = false;
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    }
    if (stackTrace == null) {
      return null;
    }
    return ExceptionInfo(err: catchErr, stackTrace: stackTrace);
  }

  Future<ExceptionInfo?> restore(File file, LoadingProgressController loadingController) async {
    if (_processing) {
      throw 'Backup or Restore processing';
    }
    final completer = Completer<ExceptionInfo?>();
    _processing = true;
    _cancel.value = false;
    final storeDir = Directory(appConfig.rootStorePath);
    await storeDir.create(recursive: true);
    final tempDir = await storeDir.createTemp("temp_");
    dynamic catchErr;
    StackTrace? stackTrace;
    try {
      assert(_handlers[0] is VersionBackupHandler);
      await ZipFile.openAndExtractAsync(file.path, tempDir.path);
      final versionHandler = _handlers[0] as VersionBackupHandler;
      final versionContent = await File("${tempDir.path}/${versionHandler.name}".normalizePath).readAsBytes();
      final versionMap = jsonDecode(utf8.decode(versionContent)) as Map<dynamic, dynamic>;
      final backupVersion = BackupVersionInfo.fromJson(versionMap.cast());
      Log.debug(tag, "backupVersion $backupVersion");
      var totalRestoreCnt = 0;
      for (var handler in _handlers.sublist(1)) {
        final name = handler.name;
        _testCancel();
        final binFile = File("${tempDir.path}/$name");
        if (!await binFile.exists()) {
          Log.warn(tag, "file not found: $name");
          continue;
        }
        final fileStream = binFile.openRead().transform(BackupDataPacketSplitter(endian: _endian, headerLen: _headerLen));
        await for (var bytes in fileStream) {
          _testCancel();
          try {
            final rid = await handler.restore(Uint8List.fromList(bytes), backupVersion, tempDir,_cancel, (rid) => _onRestoreDone(rid, loadingController, completer));
            if (rid != null) {
              _restoreIds.add(rid);
              loadingController.total = ++totalRestoreCnt;
            }
          } catch (err, stack) {
            Log.error(tag, "${handler.runtimeType} backup restore failed! data: $bytes, $err", stack);
          }
        }
      }
    } catch (err, stack) {
      catchErr = err;
      stackTrace = stack;
      Log.debug(tag, "backup restore failed! $err,$stack");
    } finally {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    }
    _processing = false;
    _cancel.value = false;
    if (stackTrace != null) {
      final exInfo = ExceptionInfo(err: catchErr, stackTrace: stackTrace);
      completer.complete(null);
      return Future.value(exInfo);
    }
    return completer.future;
  }

  void _onRestoreDone(int restoreId, LoadingProgressController controller, Completer<ExceptionInfo?> completer) {
    _restoreIds.remove(restoreId);
    controller.value++;
    if (controller.value == controller.total && _restoreIds.isEmpty) {
      completer.complete(null);
    }
  }
}

final backupHandler = BackupHandler.instance;
