import 'dart:async';

import 'package:clipshare/core/database/app_database.dart';
import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/database/dao/history_dao.dart';
import 'package:clipshare/core/database/dao/operation_record_dao.dart';
import 'package:clipshare/core/services/clipboard/clipboard_source_provider.dart';
import 'package:clipshare/core/services/transport/storage/storage_provider.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'operation_record_cleanup_provider.g.dart';

/// 操作记录级联清理
@Riverpod(keepAlive: true)
class OperationRecordCleanup extends _$OperationRecordCleanup {
  static const tag = 'OperationRecordCleanup';

  AppDatabase get _db => ref.read(appDbProvider).requireValue;

  OperationRecordDao get _opRecordDao => _db.operationRecordDao;

  HistoryDao get _historyDao => _db.historyDao;

  StorageNotifier get _storage => ref.read(storageProvider.notifier);

  ClipboardSourceNotifier get _clipboardSource => ref.read(clipboardSourceProvider.notifier);

  @override
  void build() {}

  /// 删除单条 data 的操作记录与同步记录；
  /// 存储服务运行中时尽力清理云端对应文件。
  Future<void> deleteByDataWithCascade(String data) async {
    final records = await _opRecordDao.deleteByDataWithCascade(data);
    _deleteFromStorage(records);
  }

  /// 删除历史及其标签的级联数据，随后清理云端文件并回收未使用的来源信息。
  Future<void> deleteHistoryCascade(int id) async {
    final records = await _historyDao.deleteByCascade(id);
    _deleteFromStorage(records);
    //级联删除后回收无历史引用的来源
    await _clipboardSource.removeNotUsed();
  }

  /// 存储服务运行中时清理云端文件
  void _deleteFromStorage(List<OperationRecord> records) {
    if (records.isEmpty) {
      return;
    }
    final storage = _storage;
    if (!storage.running) {
      return;
    }
    try {
      unawaited(storage.deleteOpRecords(records));
    } catch (err, stack) {
      logger.error(tag, err, stack);
    }
  }
}
