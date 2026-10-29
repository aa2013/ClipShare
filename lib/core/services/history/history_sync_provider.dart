import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:clipshare/core/constants/app_constants.dart';
import 'package:clipshare/core/constants/platform_constants.dart';
import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/database/dao/app_info_dao.dart';
import 'package:clipshare/core/database/dao/history_dao.dart';
import 'package:clipshare/core/database/dao/history_tag_dao.dart';
import 'package:clipshare/core/database/dao/operation_record_dao.dart';
import 'package:clipshare/core/database/tables/app_info.dart';
import 'package:clipshare/core/database/tables/history.dart';
import 'package:clipshare/core/database/tables/operation_record.dart';
import 'package:clipshare/core/platform/channels/android/android_channel_provider.dart';
import 'package:clipshare/core/runtime/snowflake/id_provider.dart';
import 'package:clipshare/core/services/clipboard/clipboard_source_provider.dart';
import 'package:clipshare/core/services/device/local_device_info.dart';
import 'package:clipshare/core/services/device/local_device_info_provider.dart';
import 'package:clipshare/core/services/history/history_event.dart';
import 'package:clipshare/core/services/history/history_recorder_provider.dart';
import 'package:clipshare/core/services/notify/notify_provider.dart';
import 'package:clipshare/core/services/operation_record/operation_record_cleanup_provider.dart';
import 'package:clipshare/core/services/permission/permission_helper.dart';
import 'package:clipshare/core/services/transport/message_sender/message_sender_provider.dart';
import 'package:clipshare/core/services/transport/message_sync/message_sync_event.dart';
import 'package:clipshare/core/services/transport/message_sync/message_sync_provider.dart';
import 'package:clipshare/core/services/transport/message_sync/sync_push_provider.dart';
import 'package:clipshare/core/settings/app_paths/app_paths.dart';
import 'package:clipshare/core/settings/app_paths/app_paths_provider.dart';
import 'package:clipshare/core/settings/notification/notification_settings.dart';
import 'package:clipshare/core/settings/notification/notification_settings_provider.dart';
import 'package:clipshare/core/settings/sync/sync_settings.dart';
import 'package:clipshare/core/settings/sync/sync_settings_provider.dart';
import 'package:clipshare/shared/extensions/string_extension.dart';
import 'package:clipshare/shared/models/module.dart';
import 'package:clipshare/shared/models/op_method.dart';
import 'package:clipshare/shared/utils/file_util.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:clipshare/shared/utils/snowflake.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter_image_gallery_saver/flutter_image_gallery_saver.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'history_sync_provider.g.dart';

/// 历史记录同步处理器
@Riverpod(keepAlive: true)
class HistorySyncNotifier extends _$HistorySyncNotifier {
  static const tag = 'HistorySyncNotifier';
  static const _mobileNotifyKey = 'showMobileNotify';
  static const _mobileNotifyMaxAge = Duration(seconds: 10);
  static const _mobileNotifyDuration = Duration(seconds: 2);
  static const _appInfoWaitInterval = Duration(milliseconds: 200);
  static const _appInfoWaitAttempts = 10;

  final _imageSaver = ImageGallerySaver();

  MessageSyncNotifier get _syncNotifier => ref.read(messageSyncProvider.notifier);

  HistoryRecorderNotifier get _recorder => ref.read(historyRecorderProvider.notifier);

  HistoryDao get _historyDao => ref.read(appDbProvider).requireValue.historyDao;

  OperationRecordCleanup get _opRecordCleanup => ref.read(operationRecordCleanupProvider.notifier);

  OperationRecordDao get _opRecordDao => ref.read(appDbProvider).requireValue.operationRecordDao;

  HistoryTagDao get _historyTagDao => ref.read(appDbProvider).requireValue.historyTagDao;

  AppInfoDao get _appInfoDao => ref.read(appDbProvider).requireValue.appInfoDao;

  ClipboardSourceNotifier get _sourceNotifier => ref.read(clipboardSourceProvider.notifier);

  ClipboardSourceState get _sourceState => ref.read(clipboardSourceProvider).requireValue;

  NotificationSettings get _notificationSettings => ref.read(notificationSettingsProvider).requireValue;

  NotifyNotifier get _notifyNotifier => ref.read(notifyProvider.notifier);

  MessageSenderNotifier get _messageSender => ref.read(messageSenderProvider.notifier);

  SyncPushNotifier get _syncPushNotifier => ref.read(syncPushProvider.notifier);

  Snowflake get _idGenerator => ref.read(idProvider);

  LocalDeviceInfo get _localDeviceInfo => ref.read(localDeviceInfoProvider).requireValue;

  SyncSettings get _syncSettings => ref.read(syncSettingsProvider).requireValue;

  AndroidChannelNotifier get _androidChannel => ref.read(androidChannelProvider.notifier);

  AppPaths get _appPaths => ref.read(appPathsProvider).requireValue;

  BaseDeviceInfo get _baseDevInfo => _localDeviceInfo.baseDeviceInfo;

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
        } else if (event is HistorySourceSyncEvent) {
          success = await _applyHistorySourceEvent(event);
        } else {
          continue;
        }
        if (!success) {
          continue;
        }
        _syncNotifier.emitPendingAckFor(event);
      } catch (err, stack) {
        logger.error(tag, err, stack);
      }
    }
  }

  /// 处理历史记录内容事件，通知展示失败不影响入库和同步确认。
  Future<bool> _applyHistoryEvent(HistorySyncEvent event) async {
    var history = event.history;
    final id = history.id;
    //删除操作
    if (event.method == .delete) {
      await _opRecordCleanup.deleteHistoryCascade(id);
      _emitDelta(event.history, .delete);
      return false;
    }

    ///图片类型
    if (event is HistoryImageSyncEvent) {
      final localPath = await _saveImage(event.fileName, event.data);
      history = history.copyWith(content: localPath);
    }
    if (event is HistoryNotificationSyncEvent) {
      await _showMobileNotification(event);
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

  /// 展示开启通知提醒且记录时间与当前时间相差不超过十秒的同步通知。
  Future<void> _showMobileNotification(HistoryNotificationSyncEvent event) async {
    try {
      if (!_notificationSettings.enableShowMobileNotification) {
        return;
      }
      final history = event.history;
      final offsetMs = DateTime.now().difference(DateTime.parse(history.time)).inMilliseconds.abs();
      if (offsetMs > _mobileNotifyMaxAge.inMilliseconds) {
        logger.debug(tag, 'Skip outdated mobile notification, offset: ${offsetMs}ms');
        return;
      }
      final appInfo = await _getNotificationAppInfo(event);
      final iconUri = await _cacheNotificationIcon(appInfo);
      final notifier = _notifyNotifier;
      final notifyId = await notifier.notify(
        title: event.title ?? '',
        content: event.content ?? '',
        key: _mobileNotifyKey,
        notificationLogoUri: iconUri,
      );
      if (notifyId != null) {
        Future.delayed(_mobileNotifyDuration, () {
          notifier.cancel(_mobileNotifyKey, notifyId);
        });
      }
    } catch (err, stack) {
      logger.error(tag, 'Show mobile notification failed: $err', stack);
    }
  }

  /// 按应用当前图标更新磁盘缓存；无图标或缓存失败时返回空值，使用默认通知图标。
  Future<Uri?> _cacheNotificationIcon(AppInfo? appInfo) async {
    if (appInfo == null || appInfo.iconB64.isEmpty) {
      return null;
    }
    try {
      final bytes = appInfo.iconBytes;
      if (bytes.isEmpty) {
        return null;
      }
      final file = File(p.join(_appPaths.documentsPath, 'appIcons', '${appInfo.appId}.png'));
      final cached = await file.exists() ? await file.readAsBytes() : null;
      if (!listEquals(cached, bytes)) {
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes);
      }
      return file.uri;
    } catch (err, stack) {
      logger.warn(tag, 'Cache notification icon failed: $err, $stack');
      return null;
    }
  }

  /// 按事件来源查找应用信息，缺失时向发送端请求并有限等待缓存更新。
  Future<AppInfo?> _getNotificationAppInfo(HistoryNotificationSyncEvent event) async {
    final appId = event.history.source ?? event.pkg;
    if (appId == null || appId.isEmpty) {
      return null;
    }
    var appInfo = _sourceState.getAppInfoByAppId(appId);
    if (appInfo != null) {
      return appInfo;
    }
    try {
      await _messageSender.sendToDevice(event.sender.guid, .reqAppInfo, {'appId': appId});
    } catch (err, stack) {
      logger.warn(tag, 'Request notification app info failed: $err, $stack');
      return null;
    }
    for (var i = 0; i < _appInfoWaitAttempts; i++) {
      await Future.delayed(_appInfoWaitInterval);
      appInfo = _sourceState.getAppInfoByAppId(appId);
      if (appInfo != null) {
        return appInfo;
      }
    }
    return null;
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

  /// 处理历史记录来源事件。
  Future<bool> _applyHistorySourceEvent(HistorySourceSyncEvent event) async {
    final method = event.method;
    if (method != .update && method != .delete) {
      return false;
    }
    final id = event.historyId;
    final history = await _historyDao.getById(id);
    if (history == null) {
      //源不存在，避免反复补推，强制忽略
      return true;
    }
    final sourceAppId = event.sourceAppId;
    final int? affectedRows;
    if (event.method == .delete || sourceAppId == null || sourceAppId.isEmpty) {
      affectedRows = await _historyDao.clearHistorySource(id);
    } else {
      affectedRows = await _historyDao.updateHistorySource(id, sourceAppId);
    }
    if ((affectedRows ?? 0) <= 0) {
      return false;
    }
    await _sourceNotifier.removeNotUsed();
    final updated = await _historyDao.getById(id);
    if (updated != null) {
      _emitDelta(updated, .update);
    }
    return true;
  }

  /// 落库后通知历史列表增量刷新
  void _emitDelta(History history, OpMethod operation) {
    _recorder.emitDelta(
      HistoryDeltaEvent(
        history: history,
        operation: operation,
        fromSync: true,
      ),
    );
  }

  /// 把内嵌图片字节写入本机图片目录，返回本地路径
  Future<String> _saveImage(String fileName, Uint8List data) async {
    //todo 后续这里需要再审查一遍优化项
    final saveToPictures = _syncSettings.saveToPictures;
    final safeName = FileUtil.sanitizeReceivedFileName(fileName.split(RegExp(r'[\\/]')).last);
    var dir = _appPaths.fileStorePath;
    if (isAndroid) {
      dir = saveToPictures ? '$androidPicturesPath/$appName' : _appPaths.imageStorePath;
      final osVersion = _localDeviceInfo.androidOsVersion;
      final rootStorePath = _appPaths.rootStorePath;
      if (!await PermissionHelper.testAndroidStoragePerm(rootStorePath, osVersion, dir)) {
        await PermissionHelper.reqAndroidStoragePerm(rootStorePath, osVersion, dir);
      }
    } else if (isIOS && saveToPictures) {
      if (await PermissionHelper.checkIOSPhotoPermission()) {
        await _imageSaver.saveImage(data);
      } else {
        logger.warn(tag, 'no photo permission, skip saving image to album');
      }
    }
    final file = File('$dir${Platform.pathSeparator}$safeName');
    await file.parent.create(recursive: true);
    if (!await file.exists()) {
      await file.writeAsBytes(data, flush: true);
      if (isAndroid && saveToPictures) {
        _androidChannel.notifyMediaScan(file.path);
      }
    }
    return file.path;
  }

  /// 重新同步历史内容、标签和来源信息
  Future<void> resync(int historyId) async {
    final history = await _historyDao.getById(historyId);
    if (history == null) {
      logger.warn(tag, 'History is null: $historyId');
      return;
    }
    // 历史内容
    await _pushResyncEntity(.history, historyId);

    // 标签
    final tags = await _historyTagDao.getAllByHisId(historyId);
    for (final tag in tags) {
      await _pushResyncEntity(.tag, tag.id);
    }

    // 来源信息
    final source = history.source;
    if (source == null || source.isEmpty) {
      return;
    }
    final appInfo = await _appInfoDao.getByUniqueIndex(history.devId, source);
    if (appInfo == null) {
      logger.warn(tag, 'AppInfo is null, historyId = $historyId, source = $source');
      return;
    }
    await _pushResyncEntity(.appInfo, appInfo.id);
  }

  /// 创建并持久化操作记录后推送，确保 ack 和后续补数可追踪。
  Future<void> _pushResyncEntity(Module module, Object data) async {
    final record = newOperationRecord(
      _idGenerator,
      _baseDevInfo,
      module,
      OpMethod.add,
      data,
    );
    await _opRecordDao.add(record);
    await _syncPushNotifier.pushRecord(record);
  }
}
