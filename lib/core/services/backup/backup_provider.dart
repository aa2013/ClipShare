import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:clipshare/core/database/app_database.dart';
import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/runtime/snowflake/id_provider.dart';
import 'package:clipshare/core/services/backup/backup_data_packet_splitter.dart';
import 'package:clipshare/core/services/backup/backup_result.dart';
import 'package:clipshare/core/services/backup/backup_type.dart';
import 'package:clipshare/core/services/backup/backup_version_info.dart';
import 'package:clipshare/core/services/backup/base_backup_handler.dart';
import 'package:clipshare/core/services/backup/handlers/app_info_backup_handler.dart';
import 'package:clipshare/core/services/backup/handlers/config_backup_handler.dart';
import 'package:clipshare/core/services/backup/handlers/device_backup_handler.dart';
import 'package:clipshare/core/services/backup/handlers/history_backup_handler.dart';
import 'package:clipshare/core/services/backup/handlers/history_tag_backup_handler.dart';
import 'package:clipshare/core/services/backup/handlers/operation_record_backup_handler.dart';
import 'package:clipshare/core/services/backup/handlers/operation_sync_backup_handler.dart';
import 'package:clipshare/core/services/backup/handlers/rule_backup_handler.dart';
import 'package:clipshare/core/services/backup/handlers/script_module_backup_handler.dart';
import 'package:clipshare/core/services/backup/handlers/version_backup_handler.dart';
import 'package:clipshare/core/services/device/local_device_info.dart';
import 'package:clipshare/core/services/device/local_device_info_provider.dart';
import 'package:clipshare/core/settings/app_paths/app_paths.dart';
import 'package:clipshare/core/settings/app_paths/app_paths_provider.dart';
import 'package:clipshare/shared/exceptions/user_cancel_backup_exception.dart';
import 'package:clipshare/shared/extensions/string_extension.dart';
import 'package:clipshare/shared/extensions/time_extension.dart';
import 'package:clipshare/shared/models/exception_info.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:clipshare/shared/utils/parallerl_task.dart';
import 'package:clipshare/shared/utils/snowflake.dart';
import 'package:clipshare/shared/widgets/loading/loading.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:zip_flutter/zip_flutter.dart';

part 'backup_provider.g.dart';

@Riverpod(keepAlive: true)
class BackupNotifier extends _$BackupNotifier {
  static const tag = 'BackupNotifier';

  /// 备份包内数据包长度头字节数
  static const _headerLen = 4;

  /// 备份包内数据包字节序
  static const _endian = Endian.little;

  /// 备份/恢复进行中冲突提示
  static const _processingError = 'Backup or Restore processing';

  /// 临时目录名前缀
  static const _tempDirPrefix = 'temp_';

  AppDatabase get _db => ref.read(appDbProvider).requireValue;

  AppPaths get _appPaths => ref.read(appPathsProvider).requireValue;

  LocalDeviceInfo get _localDevInfo => ref.read(localDeviceInfoProvider).requireValue;

  Snowflake get _snowflake => ref.read(idProvider);

  /// 表处理器注册列表，Version 必须保持首位
  late final List<BaseBackupHandler> _handlers;

  /// 恢复进度跟踪 id 集合，全部落库后恢复流程才算完成
  final _restoreIds = <int>{};

  bool _processing = false;

  /// 取消令牌源，每次备份/恢复开始时重建，操作结束后保持取消状态以跳过尚未执行的落库任务
  CancelTokenSource _cancelSource = CancelTokenSource();

  @override
  void build() {
    final db = _db;
    final localDevInfo = _localDevInfo;
    final appPaths = _appPaths;
    final snowflake = _snowflake;
    _handlers = [
      VersionBackupHandler(db, localDevInfo),
      ConfigBackupHandler(db, snowflake),
      AppInfoBackupHandler(db, snowflake),
      DeviceBackupHandler(db, localDevInfo, snowflake),
      HistoryBackupHandler(db, appPaths, snowflake),
      HistoryTagBackupHandler(db, snowflake),
      OperationRecordBackupHandler(db, snowflake),
      OperationSyncBackupHandler(db, snowflake),
      RuleBackupHandler(db, snowflake),
      ScriptModuleBackupHandler(db, snowflake),
    ];
  }

  /// 取消进行中的备份或恢复
  void cancel() {
    _cancelSource.cancel();
  }

  /// 已取消时抛出 [UserCancelBackup] 中断流程
  void _testCancel() {
    if (_cancelSource.token.isCanceled) {
      throw UserCancelBackup();
    }
  }

  /// 执行备份，将所选备份项打包为 zip 文件写入 [storeDir]
  Future<BackupResult> backup(Directory storeDir, List<BackupType> types) async {
    _restoreIds.clear();
    await storeDir.create(recursive: true);
    final tempDir = await storeDir.createTemp(_tempDirPrefix);
    if (_processing) {
      throw _processingError;
    }
    _processing = true;
    _cancelSource = CancelTokenSource();
    dynamic catchErr;
    StackTrace? stackTrace;
    try {
      for (var handler in _handlers) {
        //版本信息必须写入，其他的不在备份的范围内的跳过
        final backupType = handler.backupType;
        if (backupType != BackupType.version && !types.contains(backupType)) {
          continue;
        }
        final filename = backupType.filename;
        _testCancel();
        final file = File('${tempDir.path}/$filename'.normalizePath);
        final writer = file.openWrite();
        logger.info(tag, 'Start backup $filename...');
        await for (var bytes in handler.loadData(tempDir)) {
          try {
            _testCancel();
          } catch (err) {
            await writer.close();
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
        logger.info(tag, 'backup $filename finished');
      }
      final dateStr = DateTime.now().format('yyyyMMdd');
      final backupFileName = 'backup-${_localDevInfo.localName}-$dateStr.zip';
      final zipPath = '${storeDir.path}/$backupFileName';
      var zip = ZipFile.open(zipPath);
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
      logger.info(tag, 'backup all finished!!!');
      return BackupResult(success: true, localPath: zipPath, exception: null);
    } catch (err, stack) {
      catchErr = err;
      stackTrace = stack;
      logger.debug(tag, 'backup failed! Error: $err,$stack');
      final ex = ExceptionInfo(err: catchErr, stackTrace: stackTrace);
      return BackupResult(success: false, localPath: null, exception: ex);
    } finally {
      _processing = false;
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    }
  }

  /// 从备份包 [file] 恢复所选备份项，[loadingController] 接收恢复进度
  Future<ExceptionInfo?> restore(File file, LoadingProgressController loadingController, List<BackupType> types) async {
    if (_processing) {
      throw _processingError;
    }
    final completer = Completer<ExceptionInfo?>();
    _processing = true;
    _cancelSource = CancelTokenSource();
    final storeDir = Directory(_appPaths.rootStorePath);
    await storeDir.create(recursive: true);
    final tempDir = await storeDir.createTemp(_tempDirPrefix);
    dynamic catchErr;
    StackTrace? stackTrace;
    try {
      assert(_handlers[0] is VersionBackupHandler);
      await ZipFile.openAndExtractAsync(file.path, tempDir.path);
      final versionHandler = _handlers[0] as VersionBackupHandler;
      final versionContent = await File('${tempDir.path}/${versionHandler.backupType.filename}'.normalizePath).readAsBytes();
      final versionMap = jsonDecode(utf8.decode(versionContent)) as Map<dynamic, dynamic>;
      final backupVersion = BackupVersionInfo.fromJson(versionMap.cast());
      logger.debug(tag, 'backupVersion $backupVersion');
      var totalRestoreCnt = 0;
      final cancelToken = _cancelSource.token;
      for (var handler in _handlers.sublist(1)) {
        //不在恢复的范围内的跳过
        final backupType = handler.backupType;
        if (!types.contains(backupType)) {
          continue;
        }
        final filename = backupType.filename;
        _testCancel();
        final binFile = File('${tempDir.path}/$filename');
        if (!await binFile.exists()) {
          logger.warn(tag, 'file not found: $filename');
          continue;
        }
        final fileStream = binFile.openRead().transform(
          BackupDataPacketSplitter(
            endian: _endian,
            headerLen: _headerLen,
          ),
        );
        await for (var bytes in fileStream) {
          _testCancel();
          try {
            final rid = await handler.restore(
              Uint8List.fromList(bytes),
              backupVersion,
              tempDir,
              cancelToken,
              (rid) => _onRestoreDone(rid, loadingController, completer),
            );
            if (rid != null) {
              _restoreIds.add(rid);
              loadingController.total = ++totalRestoreCnt;
            }
          } catch (err, stack) {
            logger.error(tag, '${handler.runtimeType} backup restore failed! data: $bytes, $err', stack);
          }
        }
      }
    } catch (err, stack) {
      catchErr = err;
      stackTrace = stack;
      logger.debug(tag, 'backup restore failed! $err,$stack');
    } finally {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    }
    _processing = false;
    if (stackTrace != null) {
      final exInfo = ExceptionInfo(err: catchErr, stackTrace: stackTrace);
      completer.complete(null);
      return Future.value(exInfo);
    }
    return completer.future;
  }

  /// 单条恢复记录落库回调，全部记录落库后完成恢复流程
  void _onRestoreDone(int restoreId, LoadingProgressController controller, Completer<ExceptionInfo?> completer) {
    _restoreIds.remove(restoreId);
    controller.value++;
    if (controller.value == controller.total && _restoreIds.isEmpty) {
      completer.complete(null);
    }
  }
}
