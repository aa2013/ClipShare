import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:clipshare/core/constants/platform_constants.dart';
import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/database/dao/history_dao.dart';
import 'package:clipshare/core/database/dao/operation_record_dao.dart';
import 'package:clipshare/core/database/tables/history.dart';
import 'package:clipshare/core/services/history/history_event.dart';
import 'package:clipshare/core/services/history/history_recorder_provider.dart';
import 'package:clipshare/core/services/transport/message_sync/message_sync_event.dart';
import 'package:clipshare/core/services/transport/message_sync/message_sync_provider.dart';
import 'package:clipshare/core/settings/app_paths/app_paths_provider.dart';
import 'package:clipshare/shared/extensions/string_extension.dart';
import 'package:clipshare/shared/models/op_method.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'history_sync_provider.g.dart';

/// 历史记录同步处理器
@Riverpod(keepAlive: true)
class HistorySyncNotifier extends _$HistorySyncNotifier {
  static const tag = 'HistorySyncNotifier';

  MessageSyncNotifier get _syncNotifier => ref.read(messageSyncProvider.notifier);

  HistoryRecorderNotifier get _recorder => ref.read(historyRecorderProvider.notifier);

  HistoryDao get _historyDao => ref.read(appDbProvider).requireValue.historyDao;

  OperationRecordDao get _opRecordDao => ref.read(appDbProvider).requireValue.operationRecordDao;

  @override
  void build() {
    unawaited(_listenSyncEvents());
    unawaited(_listenAckSyncEvents());
  }

  Future<void> _listenAckSyncEvents() async {
    await for (final event in _syncNotifier.ackSyncEvents) {
      try {
        if (event is! HistoryAckSyncEvent) {
          continue;
        }
        final record = await _opRecordDao.getById(event.opId);
        if (record == null) {
          logger.warn(tag, 'ack operation record not found, opId = ${event.opId}, sender = ${event.sender.guid}');
          continue;
        }
        if (record.method != .add) {
          continue;
        }
        final historyId = int.tryParse(record.data);
        if (historyId == null) {
          logger.warn(tag, 'invalid history id in operation record, opId = ${event.opId}, data = ${record.data}');
          continue;
        }
        final history = await _historyDao.getById(historyId);
        if (history == null) {
          logger.warn(tag, 'history not found when ack, opId = ${event.opId}, historyId = $historyId');
          continue;
        }
        if (history.sync) {
          logger.debug(tag, 'history already synced when ack, opId = ${event.opId}, historyId = $historyId');
          continue;
        }
        final rows = await _historyDao.setSync(historyId, true) ?? 0;
        if (rows <= 0) {
          logger.warn(tag, 'set history sync failed, opId = ${event.opId}, historyId = $historyId');
          continue;
        }
        _emitDelta(history.copyWith(sync: true), .update);
      } catch (err, stack) {
        logger.error(tag, err, stack);
      }
    }
  }

  Future<void> _listenSyncEvents() async {
    await for (final event in _syncNotifier.syncEvents) {
      try {
        var success = false;
        if (event is HistorySyncEvent) {
          success = await _applyHistoryEvent(event);
        } else if (event is HistoryTopSyncEvent) {
          success = await _applyHistoryTopEvent(event);
        } else {
          continue;
        }
        if (!success) {
          continue;
        }
        _syncNotifier.emitPendingAck(
          HistoryAckSyncEvent(
            sender: event.sender,
            opId: event.opId,
          ),
        );
      } catch (err, stack) {
        logger.error(tag, err, stack);
      }
    }
  }

  /// 处理历史记录内容事件
  Future<bool> _applyHistoryEvent(HistorySyncEvent event) async {
    var history = event.history;
    final id = history.id;
    //删除操作
    if (event.method == .delete) {
      await _historyDao.deleteByCascade(id);
      _emitDelta(event.history, .delete);
      return false;
    }

    ///图片类型
    if (event is HistoryImageSyncEvent) {
      final localPath = await _saveImage(event.opId, event.fileName, event.data);
      history = history.copyWith(content: localPath);
    }
    history = history.copyWith(sync: true);
    final bool success;
    if (event.method == .add) {
      success = await _historyDao.add(history) > 0;
    } else {
      success = await _historyDao.updateHistory(history) > 0;
    }
    if (success) {
      _emitDelta(history, event.method);
    } else {
      final subContent = history.content.substringMinLen(0, 200);
      logger.warn(tag, 'insert history failed, id = $id, content = $subContent');
    }
    return success;
  }

  /// 处理历史记录置顶/取消置顶事件
  Future<bool> _applyHistoryTopEvent(HistoryTopSyncEvent event) async {
    final id = event.historyId;
    var isTop = event.top;
    var history = await _historyDao.getById(id);
    if (history == null) {
      return false;
    }
    history = history.copyWith(top: isTop);
    final success = await _historyDao.updateHistory(history) > 0;
    if (success) {
      _emitDelta(history, .update);
    }
    return success;
  }

  /// 落库后通知历史列表增量刷新
  void _emitDelta(History history, OpMethod operation) {
    _recorder.emitDelta(
      HistoryDeltaEvent(history: history, operation: operation),
    );
  }

  /// 把内嵌图片字节写入本机图片目录，返回本地路径。
  Future<String> _saveImage(int opId, String fileName, Uint8List data) async {
    final appPaths = await ref.read(appPathsProvider.future);
    final dir = isAndroid ? appPaths.androidPrivatePicturesPath : appPaths.screenShotStorePath;
    //todo 使用dev版本的实现
    // 发送端文件名可能带路径或重名，只保留末段并用操作 id 去重
    final safeName = '${opId}_${fileName.split(RegExp(r'[\\/]')).last}';
    final file = File('$dir${Platform.pathSeparator}$safeName');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(data, flush: true);
    return file.path;
  }

  /// 重新同步历史内容、标签和来源信息。
  Future<void> resync(int historyId) async {
    final history = await _historyDao.getById(historyId);
    if (history == null) {
      logger.warn(tag, 'History is null: $historyId');
      return;
    }
    //todo
    // var opRecord = newOperationRecord(
    //   Module.history,
    //   OpMethod.add,
    //   historyId.toString(),
    // );
    // var result = await MissingDataSyncHandler.process(opRecord);
    // await DataSender.sendData2All(MsgType.sync, result.result);
    //
    // final tags = await attachedDatabase.historyTagDao.getAllByHisId(historyId);
    // for (var tag in tags) {
    //   opRecord = newOperationRecord(
    //     Module.tag,
    //     OpMethod.add,
    //     tag.id.toString(),
    //   );
    //   result = await MissingDataSyncHandler.process(opRecord);
    //   await DataSender.sendData2All(MsgType.sync, result.result);
    // }
    //
    // if (history.source != null) {
    //   final devId = history.devId;
    //   final sourceService = Get.find<ClipboardSourceService>();
    //   final appInfo = sourceService.appInfos.where((item) => item.devId == devId && history.source == item.appId).firstOrNull;
    //   if (appInfo == null) {
    //     logger.warn(tag, 'AppInfo is null source = ${history.source}');
    //     return;
    //   }
    //   opRecord = newOperationRecord(
    //     Module.appInfo,
    //     OpMethod.add,
    //     appInfo.id,
    //   );
    //   result = await MissingDataSyncHandler.process(opRecord);
    //   await DataSender.sendData2All(MsgType.sync, result.result);
    // }
  }
}
