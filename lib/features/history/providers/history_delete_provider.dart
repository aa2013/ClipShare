import 'dart:io';

import 'package:clipshare/core/constants/platform_constants.dart';
import 'package:clipshare/core/database/app_database.dart';
import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/database/extensions/history_extension.dart';
import 'package:clipshare/core/database/tables/history.dart';
import 'package:clipshare/core/database/tables/operation_record.dart';
import 'package:clipshare/core/platform/channels/android/android_channel_provider.dart';
import 'package:clipshare/core/runtime/snowflake/id_provider.dart';
import 'package:clipshare/core/services/device/local_device_info.dart';
import 'package:clipshare/core/services/device/local_device_info_provider.dart';
import 'package:clipshare/core/services/history/history_event.dart';
import 'package:clipshare/core/services/operation_record/operation_record_cleanup_provider.dart';
import 'package:clipshare/core/services/transport/message_sync/sync_push_provider.dart';
import 'package:clipshare/features/history/providers/history_provider.dart';
import 'package:clipshare/shared/models/module.dart';
import 'package:clipshare/shared/models/op_method.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:clipshare/shared/utils/snowflake.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'history_delete_provider.g.dart';

/// 历史记录删除服务：级联删除记录、同步删除操作并可选清理本地文件。
/// 供历史列表与文件传输页的历史记录列表共用。
@Riverpod(keepAlive: true)
class HistoryDeleteNotifier extends _$HistoryDeleteNotifier {
  static const tag = 'HistoryDeleteNotifier';

  Snowflake get _idGenerator => ref.read(idProvider);

  BaseDeviceInfo get _self => ref.read(localDeviceInfoProvider).requireValue.baseDeviceInfo;

  SyncPushNotifier get _syncPushNotifier => ref.read(syncPushProvider.notifier);

  AndroidChannelNotifier get _androidChannel => ref.read(androidChannelProvider.notifier);

  Future<AppDatabase> get _appDb => ref.read(appDbProvider.future);

  OperationRecordCleanup get _cleanup => ref.read(operationRecordCleanupProvider.notifier);

  HistoriesNotifier get _historiesNotifier => ref.read(historiesProvider.notifier);

  @override
  void build() {}

  /// 删除单条历史记录。
  /// [deleteFile] 连带删除本地文件。
  /// [onlyDeleteLocal] 为 true 时不产生同步删除记录。
  /// 返回是否删除成功。
  Future<bool> delete(
    History history, {
    bool deleteFile = false,
    bool onlyDeleteLocal = false,
  }) async {
    try {
      final db = await _appDb;
      // 级联删除并清理云端存储、回收无引用的来源数据
      await _cleanup.deleteHistoryCascade(history.id);
      // 通知事件流，让列表移除该记录
      _historiesNotifier.addDelta(
        HistoryDeltaEvent(
          history: history,
          operation: OpMethod.delete,
        ),
      );
      if (!onlyDeleteLocal) {
        final opRecord = newOperationRecord(
          _idGenerator,
          _self,
          Module.history,
          OpMethod.delete,
          history.id,
        );
        await db.operationRecordDao.add(opRecord);
        await _syncPushNotifier.pushRecord(opRecord);
      }
      if (deleteFile && (history.isImage || history.isFile)) {
        final path = history.content;
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
          if (history.isImage && isAndroid) {
            _androidChannel.notifyMediaScan(path);
          }
        }
      }
      return true;
    } catch (err, stack) {
      logger.error(tag, err, stack);
      return false;
    }
  }
}
