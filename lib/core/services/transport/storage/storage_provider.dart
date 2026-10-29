import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:clipshare/core/constants/app_constants.dart';
import 'package:clipshare/core/constants/network_constants.dart';
import 'package:clipshare/core/database/app_database.dart';
import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/database/tables/operation_record.dart';
import 'package:clipshare/core/database/tables/operation_sync.dart';
import 'package:clipshare/core/extensions/database_extension.dart';
import 'package:clipshare/core/platform/channels/android/android_channel_provider.dart';
import 'package:clipshare/core/platform/channels/android/events/screen_opened_event.dart';
import 'package:clipshare/core/runtime/app_state/app_state.dart';
import 'package:clipshare/core/runtime/app_state/app_state_provider.dart';
import 'package:clipshare/core/runtime/snowflake/id_provider.dart';
import 'package:clipshare/core/services/clipboard/clipboard_source_provider.dart';
import 'package:clipshare/core/services/device/device_provider.dart';
import 'package:clipshare/core/services/device/events/device_discovery_event.dart';
import 'package:clipshare/core/services/device/events/device_lifecycle_event.dart';
import 'package:clipshare/core/services/device/local_device_info.dart';
import 'package:clipshare/core/services/device/local_device_info_provider.dart';
import 'package:clipshare/core/services/history/history_event.dart';
import 'package:clipshare/core/services/history/history_recorder_provider.dart';
import 'package:clipshare/core/services/notify/notify_provider.dart';
import 'package:clipshare/core/services/transport/file/models/file_transfer_task.dart';
import 'package:clipshare/core/services/transport/file/models/protocol/file_name_codec.dart';
import 'package:clipshare/core/services/transport/file/receiver/file_receiver_provider.dart';
import 'package:clipshare/core/services/transport/file/sender/file_send_channel.dart';
import 'package:clipshare/core/services/transport/file/sender/storage_send_channel.dart';
import 'package:clipshare/core/services/transport/message_sender/message_sender.dart';
import 'package:clipshare/core/services/transport/message_sync/message_sync_provider.dart';
import 'package:clipshare/core/services/transport/socket/discovery/discovery_provider.dart';
import 'package:clipshare/core/services/transport/socket/session/reconnect_provider.dart';
import 'package:clipshare/core/services/transport/socket/session/session_provider.dart';
import 'package:clipshare/core/settings/app_paths/app_paths_provider.dart';
import 'package:clipshare/core/settings/discovery/discovery_settings.dart';
import 'package:clipshare/core/settings/discovery/discovery_settings_provider.dart';
import 'package:clipshare/core/settings/forward/forward_server_status.dart';
import 'package:clipshare/core/settings/forward/forward_settings.dart';
import 'package:clipshare/core/settings/forward/forward_settings_provider.dart';
import 'package:clipshare/core/settings/sync/sync_settings.dart';
import 'package:clipshare/core/settings/sync/sync_settings_provider.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/enums/sync_source.dart';
import 'package:clipshare/shared/enums/transport_protocol.dart';
import 'package:clipshare/shared/exceptions/different_storage_client_type_exception.dart';
import 'package:clipshare/shared/extensions/number_extension.dart';
import 'package:clipshare/shared/extensions/string_extension.dart';
import 'package:clipshare/shared/extensions/time_extension.dart';
import 'package:clipshare/shared/models/module.dart';
import 'package:clipshare/shared/models/op_method.dart';
import 'package:clipshare/shared/models/storage/s3_config.dart';
import 'package:clipshare/shared/models/storage/web_dav_config.dart';
import 'package:clipshare/shared/models/version.dart';
import 'package:clipshare/shared/models/websocket/ws_msg_data.dart';
import 'package:clipshare/shared/models/websocket/ws_msg_type.dart';
import 'package:clipshare/shared/utils/crypto.dart';
import 'package:clipshare/shared/utils/dialog.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:clipshare/shared/utils/network_util.dart';
import 'package:clipshare/shared/utils/parallerl_task.dart';
import 'package:drift/drift.dart' show Value;
import 'package:msgpack_dart/msgpack_dart.dart' as m2;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../client/storage/storage_client.dart';
import '../client/storage/web_dav_client.dart';
import '../enums/msg_type.dart';
import '../events/forward_status_event_provider.dart';
import '../extensions/storage_config_extension.dart';
import '../heartbeat/transport_heartbeat_provider.dart';
import '../message_sync/storage_sync_record.dart';
import '../message_sync/sync_push_provider.dart';
import '../message_sync/sync_receive_dispatcher_provider.dart';
import '../models/message_data.dart';
import '../utils/notification_server_util.dart';
import 'storage_ws_service.dart';

part 'storage_provider.g.dart';

/// 结构：
/// history
/// - A
///   - 2025-09-08
///     - files
///       - 1321546
///       - filename
///     13215478545
///   - 2025-09-07
///     - files
///       - 1321546
///       - filename
///     1654646544
/// devices-info
/// - A
///   - deviceInfo.json
///   - minVersion.json
///   - version.json
/// - B
///   - deviceInfo.json
///   - minVersion.json
///   - version.json
/// app-info
/// - A
///  - 1321465456444
/// 监听网络恢复
@Riverpod(keepAlive: true)
class StorageNotifier extends _$StorageNotifier implements MessageSender {
  static const tag = 'StorageService';

  static const devicesInfoDir = 'devices-info';
  static const historyDir = 'history';
  static const appInfoDir = 'app-info';
  static const maxParallelCnt = 10;
  static const _storageOnlineHeartbeatTaskName = 'storage-online';
  static const _sameNetworkSocketGracePeriod = Duration(seconds: 3);

  /// 补拉缺失数据的冷却时长：同设备距上次补拉过近则直接跳过，避免反复全量扫描。
  static const _reloadMissingCoolDown = Duration(seconds: 60);
  static const _baseDirs = [devicesInfoDir, historyDir, appInfoDir];
  static const _minCompatibleWsVersion = SemanticVersion(1, 2, 0);
  static const _incompatibleWsVersionNotifyKey = 'storage-ws-incompatible-version';

  var _lastDate = '';
  final _cache = <String>{};

  /// 记录各设备最近一次补拉缺失数据的时间，用于心跳节流，避免重复全量扫描。
  final _lastReloadAt = <String, DateTime>{};

  /// 云端已知设备 id 缓存：启动时全量填充、收到 online 时增量补充、stop 时清空。
  /// 作为心跳广播目标集，避免每 30s 重复列举云端设备目录。
  final _cloudDeviceIds = <String>{};
  var _loadingMissingData = false;
  var _uploadingSyncFailedData = false;
  late final StorageWsService _wsService;
  int _notificationVersionRequestId = 0;

  /// 屏幕状态订阅事件流
  StreamSubscription<ScreenEvent>? _screenEventsSubscription;

  /// 设备发现事件订阅，轮次结束后尝试建立存储设备连接
  StreamSubscription<DeviceDiscoveryEvent>? _discoverySub;

  bool get running => _wsService.running;

  StorageClient? _client;

  AppDatabase get _appDb => ref.read(appDbProvider).requireValue;

  DeviceState get _deviceState => ref.read(deviceProvider).requireValue;

  DeviceNotifier get _deviceNotifier => ref.read(deviceProvider.notifier);

  TransportHeartbeatNotifier get _heartbeatNotifier => ref.read(transportHeartbeatProvider.notifier);

  ReconnectNotifier get _reconnect => ref.read(reconnectProvider.notifier);

  HistoryRecorderNotifier get _historyRecorder => ref.read(historyRecorderProvider.notifier);

  MessageSyncNotifier get _syncNotifier => ref.read(messageSyncProvider.notifier);

  NotifyNotifier get _notify => ref.read(notifyProvider.notifier);

  SyncPushNotifier get _syncPush => ref.read(syncPushProvider.notifier);

  SyncReceiveDispatcher get _syncDispatcher => ref.read(syncReceiveDispatcherProvider.notifier);

  FileReceiverNotifier get _fileReceiver => ref.read(fileReceiverProvider.notifier);

  DiscoverySettings get _discoverySettings => ref.read(discoverySettingsProvider).requireValue;

  ForwardSettings get _forwardSettings => ref.read(forwardSettingsProvider).requireValue;

  SyncSettings get _syncSettings => ref.read(syncSettingsProvider).requireValue;

  LocalDeviceInfo get _localDeviceInfo => ref.read(localDeviceInfoProvider).requireValue;

  AppState get _appState => ref.read(appStateProvider);

  AppStateNotifier get _appStateNotifier => ref.read(appStateProvider.notifier);

  BaseDeviceInfo get _self => _localDeviceInfo.baseDeviceInfo;

  String get _selfDevId => _self.guid;

  WebDAVConfig? get _webDAVConfig => _forwardSettings.webdavConfig;

  S3Config? get _s3Config => _forwardSettings.s3Config;

  @override
  void build() {
    _wsService = StorageWsService(
      connectUriBuilder: _buildWsUri,
      shouldKeepConnected: _shouldKeepWsConnected,
      pingInterval: const Duration(
        seconds: defaultWsPingIntervalTime,
      ),
      onConnected: _onWsConnected,
      onDisconnected: _onWsDisconnected,
      onMessage: _dispatchWsMessage,
      onStatusChanged: _onWsStatusChanged,
    );
    _registerStorageOnlineHeartbeatTask();
    final androidChannelNotifier = ref.read(androidChannelProvider.notifier);
    _screenEventsSubscription = androidChannelNotifier.screenEvents.listen(_onScreenEvent);
    ref.onDispose(_onDispose);
  }

  void _onDispose() {
    _screenEventsSubscription?.cancel();
    _discoverySub?.cancel();
  }

  Uri _buildWsUri() {
    late final String storageId;
    if (_forwardSettings.enableWebDAV) {
      storageId = CryptoUtil.toMD5(
        '${_webDAVConfig!.server}${_webDAVConfig!.username}',
      );
    } else {
      storageId = CryptoUtil.toMD5(
        '${_s3Config!.endPoint}${_s3Config!.bucketName}${_s3Config!.accessKey}',
      );
    }
    final connectKey = '$storageId:$_selfDevId';
    final serverHost = _forwardSettings.notificationServer.trimEnd('/');
    return Uri.parse('$serverHost/connect/$connectKey');
  }

  bool _shouldKeepWsConnected() {
    return _forwardSettings.enableStorageSync && _forwardSettings.enable && _client != null;
  }

  //region Init

  Future<bool> _createBaseDirectories() async {
    if (_client == null) return false;
    var result = true;
    final selfDevId = _selfDevId;
    final dirs = [..._baseDirs];
    final today = DateTime.now().format('yyyy-MM-dd');
    if (today != _lastDate) {
      _lastDate = today;
      dirs.add(getHistoryDatePath(selfDevId, today));
    }
    for (var dirPath in dirs) {
      final created = await _client?.createDirectory(dirPath) ?? false;
      if (!created) {
        logger.debug(tag, 'Create Directory failed: $dirPath');
        return false;
      }
    }
    return result;
  }

  Future<void> _updateBaseInfo() async {
    final client = _client;
    if (client == null) {
      logger.warn(tag, '_updateBaseInfo storage client is null');
      return;
    }
    final device = _localDeviceInfo.self.copyWith(customName: Value(_localDeviceInfo.localName));
    // WebDAV 在部分服务端上不会自动补父目录，这里统一让写文件顺带补齐路径。
    await client.createFile(
      getDeviceInfoPath(_selfDevId),
      utf8.encode(jsonEncode(device)),
      createDir: true,
    );
    await client.createFile(
      getDeviceVersionPath(_selfDevId),
      utf8.encode(jsonEncode(_localDeviceInfo.appVersion)),
      createDir: true,
    );
    await client.createFile(
      getDeviceMinVersionPath(_selfDevId),
      utf8.encode(jsonEncode(minVersion)),
      createDir: true,
    );
  }

  /// 检查并上传缺失的本机app信息
  Future<void> _checkAndUploadLocalAppInfo() async {
    final client = _client;
    if (client == null) {
      logger.warn(tag, '_checkAndUploadLocalAppInfo storage client is null');
      return;
    }
    final dirPath = getAppInfoDirectoryPath(_selfDevId);
    var result = await client.createDirectory(dirPath);
    if (!result) {
      logger.debug(tag, 'checkAndUploadLocalAppInfo failed');
      return;
    }
    final clipboardSource = await ref.read(clipboardSourceProvider.future);
    var list = clipboardSource.appInfos.where((item) => item.devId == _selfDevId).toList();
    final existsIds = (await client.list(
      path: dirPath,
    )).map((item) => item.name).toSet();
    list = list.where((item) => !existsIds.contains(item.id.toString())).toList();
    for (var appInfo in list) {
      if (!await _uploadAppInfo(appInfo)) {
        continue;
      }
    }
  }

  Future<bool> _uploadAppInfo(AppInfo appInfo) async {
    final dirPath = getAppInfoDirectoryPath(_selfDevId);
    final client = _client;
    if (client == null) {
      logger.warn(tag, '_uploadAppInfo storage client is null');
      return false;
    }
    if (!await client.createDirectory(dirPath)) {
      logger.debug(tag, '_uploadAppInfo createDirectory $dirPath failed.');
      return false;
    }
    final opRecord = newOperationRecord(
      ref.read(idProvider),
      _self,
      .appInfo,
      .add,
      appInfo.id.toString(),
    );
    final payload = await _syncPush.buildPayload(opRecord);
    final id = appInfo.id;
    final path = '$dirPath/$id';
    final success = await client.createFile(
      path,
      m2.serialize(payload.data),
      createDir: true,
    );
    if (!success) {
      logger.warn(tag, 'upload appInfo($id) failed');
      return false;
    }
    //ws send
    final devIds = _deviceState.registry.getDevIdsByStorage();
    logger.info(
      tag,
      'notify storage devices appInfo. targetCount=${devIds.length}',
    );
    for (final devId in devIds) {
      _wsService.send(WsMsgData(WsMsgType.appInfo, id.toString(), devId));
    }
    return true;
  }

  /// 检查并下载缺失的其他设备的app信息
  Future<void> _checkAndDownloadMissingAppInfo(String devId) async {
    final client = _client;
    if (client == null) {
      logger.warn(
        tag,
        '_checkAndDownloadMissingAppInfo storage client is null',
      );
      return;
    }
    final dirPath = getAppInfoDirectoryPath(devId);
    final clipboardSource = await ref.read(clipboardSourceProvider.future);
    final list = await client.list(path: dirPath);
    final cloudIds = list.where((item) => !item.isDir).map((item) => item.name).toSet();
    final existsIds = clipboardSource.appInfos.where((item) => item.devId == devId).map((item) => item.id.toString()).toSet();
    final diff = cloudIds.difference(existsIds);
    for (var id in diff) {
      try {
        await _processAppInfoMsg(WsMsgData(WsMsgType.appInfo, id, devId));
      } catch (err, stack) {
        logger.error(tag, '_checkAndDownloadMissingAppInfo error: $err', stack);
      }
    }
  }

  //endregion

  ///屏幕事件处理
  void _onScreenEvent(ScreenEvent event) {
    if (event is ScreenOpenedEvent) {
      _onScreenOpened();
    }
  }

  ///屏幕开启事件
  void _onScreenOpened() {
    // if(_client == null || _wsService.running){
    //   return;
    // }
    //如果启用了且ws断开则重连
    // unawaited(reconnectWs());
  }

  Future<void> start() async {
    if (!_forwardSettings.enableStorageSync) {
      return;
    }
    if (!_forwardSettings.enable) {
      return;
    }
    //订阅设备发现事件
    _discoverySub = _deviceNotifier.discoveryEvents.listen(_onDiscoveryEvent);
    if (_forwardSettings.enableS3 && _s3Config != null) {
      _client = _s3Config!.toClient();
    } else if (_forwardSettings.enableWebDAV && _webDAVConfig != null) {
      _client = _webDAVConfig!.toClient();
    } else {
      throw 'storage service config is null';
    }
    _updateForwardStatus(ForwardServerStatus.initializing);
    if (!await _createBaseDirectories()) {
      logger.warn(tag, 'create base directories failed!');
      _client = null;
      _updateForwardStatus(ForwardServerStatus.disconnected);
      return;
    }
    try {
      await _initCloudDeviceIds();
      await _updateBaseInfo();
      await _checkAndUploadLocalAppInfo();
      if (!await _ensureCompatibleWsVersion()) {
        await _wsService.disconnect();
        _updateForwardStatus(ForwardServerStatus.disconnected);
        return;
      }
      uploadSyncFailedData();
      // 缺失数据全量扫描统一由 _onWsConnected 在连接建立后触发，
      // 避免启动时此处再跑一遍导致同一连接期内重复全量扫描。
      await _wsService.connect();
    } catch (err, stack) {
      logger.error(tag, err, stack);
      await _wsService.disconnect();
      _updateForwardStatus(ForwardServerStatus.disconnected);
    }
  }

  Future<bool> _ensureCompatibleWsVersion() async {
    try {
      final versionText = await NotificationServerUtil.getVersion(
        _forwardSettings.notificationServer,
      );
      _appStateNotifier.updateTransportServerVersion(versionText);
      final version = SemanticVersion.parse(versionText);
      if (version >= _minCompatibleWsVersion) {
        return true;
      }
      await _showIncompatibleWsVersionTip(version);
      return false;
    } catch (err, stack) {
      logger.error(
        tag,
        'check notification server version failed: $err',
        stack,
      );
      return true;
    }
  }

  Future<void> _showIncompatibleWsVersionTip(SemanticVersion version) async {
    final text = TranslationKey.storageWsVersionIncompatibleDialogContent.trParams({
      'version': version.toString(),
      'minVersion': _minCompatibleWsVersion.toString(),
    });
    final context = navigatorKey.currentContext;
    if (context != null) {
      await dialogManager.tips(
        context,
        title: TranslationKey.storageWsVersionIncompatibleTitle.tr,
        text: text,
      );
    }
    try {
      _notify.cancelAll(_incompatibleWsVersionNotifyKey);
      await _notify.notify(
        key: _incompatibleWsVersionNotifyKey,
        title: TranslationKey.storageWsVersionIncompatibleTitle.tr,
        content: text,
      );
    } catch (err, stack) {
      logger.error(
        tag,
        'show incompatible ws version notification failed: $err',
        stack,
      );
    }
  }

  Future<void> stop() async {
    _heartbeatNotifier.stop(_storageOnlineHeartbeatTaskName);
    _cloudDeviceIds.clear();
    _client = null;
    _lastDate = '';
    await _discoverySub?.cancel();
    _discoverySub = null;
    await _wsService.disconnect();
  }

  /// 启动时列举一次云端设备目录（排除自身），填充心跳广播目标集。
  /// 此处只读取设备目录 id，不读取设备信息/版本文件；失败不影响启动。
  Future<void> _initCloudDeviceIds() async {
    final client = _client;
    if (client == null) {
      return;
    }
    final list = await client.list(path: devicesInfoDir);
    _cloudDeviceIds
      ..clear()
      ..addAll(
        list.where((item) => item.isDir && item.name != _selfDevId).map((item) => item.name),
      );
  }

  Future<void> restart() async {
    await stop();
    await start();
  }

  //region Load missing data

  Future<void> _loadMissingData() async {
    final client = _client;
    if (client == null) {
      logger.warn(tag, '_loadMissingData storage client is null');
      return;
    }
    if (!_syncSettings.autoSyncMissingData) {
      logger.warn(tag, 'autoSyncMissingData is false');
      return;
    }
    if (_loadingMissingData) {
      return;
    }
    _loadingMissingData = true;
    try {
      final clientType = client.runtimeType;

      ///检查客户端类型是否和初始的相同，如果不同则表示用户切换了中转类型，需要终止该方法
      void checkClientRuntimeType() {
        final currentType = _client?.runtimeType;
        if (clientType != currentType) {
          throw DifferentStorageClientTypeException(
            'current storage client($currentType) is not a $clientType',
          );
        }
      }

      final devices = await _loadDeviceInfosFromStorage();
      if (devices.isEmpty) {
        logger.warn(tag, 'storage devices is empty');
        return;
      }

      //add or update devices
      for (var dev in devices) {
        checkClientRuntimeType();
        await _addOrUpdateDevice(dev);
      }

      final devIds = devices.map((item) => item.guid).toList();
      await _syncMissingDataForDevices(
        devIds: devIds,
        client: client,
        checkClientRuntimeType: checkClientRuntimeType,
      );
    } finally {
      // Always release the guard so reconnects can retry missing-data sync.
      _loadingMissingData = false;
    }
  }

  /// 统一复用“按设备补拉缺失数据”的主流程，供初次连接和对端重连后补拉共用。
  Future<void> _syncMissingDataForDevices({
    required List<String> devIds,
    required StorageClient client,
    required void Function() checkClientRuntimeType,
  }) async {
    final devHistoryDirMap = await _loadDevHistoryDirectoriesFromStorage(
      devIds,
    );

    // sync item : devId -> (date -> id)
    final syncMap = <String, Map<String, List<String>>>{};
    var totalSyncCnt = 0;
    var syncedCnt = 0;

    for (var devId in devHistoryDirMap.keys) {
      final devDateSyncMap = await _collectMissingHistorySyncMapForDevice(
        devId: devId,
        client: client,
        checkClientRuntimeType: checkClientRuntimeType,
        historyDates: devHistoryDirMap[devId] ?? const <String>[],
      );
      syncMap[devId] = devDateSyncMap;
      totalSyncCnt += devDateSyncMap.values.fold(
        0,
        (prev, ids) => prev + ids.length,
      );
    }

    final List<FutureFunction> tasks = [];
    for (var devId in syncMap.keys) {
      final devDateSyncMap = syncMap[devId]!;
      for (var date in devDateSyncMap.keys) {
        final syncIds = devDateSyncMap[date]!;
        for (var id in syncIds) {
          tasks.add(() async {
            try {
              checkClientRuntimeType();
              await _readSyncData(devId, date, id, true);
            } catch (err, stack) {
              if (err is DifferentStorageClientTypeException) {
                return;
              }
              logger.error(
                tag,
                'load missing data file from storage failed! devId = $devId, date = $date, id = $id',
                stack,
              );
            } finally {
              //更新同步进度
              _syncNotifier.emitMissingDataBatch(devId, ++syncedCnt, totalSyncCnt);
            }
          });
        }
      }
    }

    await ParallelTask(tasks: tasks, maxParallelCnt: maxParallelCnt).run();
  }

  /// 按单设备收集待补拉的历史记录，保证重连补拉和首次全量补拉遵循同一筛选规则。
  Future<Map<String, List<String>>> _collectMissingHistorySyncMapForDevice({
    required String devId,
    required StorageClient client,
    required void Function() checkClientRuntimeType,
    required List<String> historyDates,
  }) async {
    await _checkAndDownloadMissingAppInfo(devId);
    final latestRecord = await _appDb.operationRecordDao.getLatestStorageSyncSuccessByDevId(devId);
    final latestDate = DateTime.parse(latestRecord?.time ?? '1970-01-01');
    final latestId = latestRecord?.id ?? 0;
    final devDateSyncMap = <String, List<String>>{};

    for (var date in historyDates) {
      if (DateTime.parse(date).isBefore(latestDate.date)) {
        continue;
      }
      final syncIds = <String>[];
      devDateSyncMap[date] = syncIds;
      try {
        final path = getHistoryDatePath(devId, date);
        final items = await client.list(path: path);
        final ids = items.where((item) => !item.isDir).map((item) => item.name).where((id) => int.parse(id) > latestId).toList();
        ids.sort((a, b) => int.parse(b) - int.parse(a));
        for (var id in ids) {
          checkClientRuntimeType();
          syncIds.add(id);
        }
      } catch (err, stack) {
        logger.error(tag, 'loadMissingData error: $err', stack);
      }
    }

    return devDateSyncMap;
  }

  Future<Map<String, List<String>>> _loadDevHistoryDirectoriesFromStorage(
    List<String> devIds,
  ) async {
    final result = <String, List<String>>{};
    final client = _client;
    if (client == null) {
      logger.warn(tag, '_loadDevHistoryDirectoriesFromStorage storage client is null');
      return result;
    }
    for (var devId in devIds) {
      try {
        final list = await client.list(path: getHistoryDirectoryPath(devId));
        final directoryNames = list.where((item) => item.isDir).map((item) => item.name).toList();
        result[devId] = directoryNames;
      } catch (err, stack) {
        logger.error(tag, err, stack);
      }
    }
    return result;
  }

  ///从存储中加载设备信息（排除自身）
  Future<List<Device>> _loadDeviceInfosFromStorage() async {
    final result = List<Device>.empty(growable: true);
    try {
      final client = _client;
      if (client == null) {
        logger.warn(tag, '_loadDeviceInfosFromStorage storage client is null');
        return result;
      }
      // 优先复用启动时填充的云端设备 id 缓存，避免每次全量扫描都重复列举 devices-info；
      // 缓存为空（如重连前未初始化）时回退列举一次，并顺带刷新缓存。
      if (_cloudDeviceIds.isEmpty) {
        final list = await client.list(path: devicesInfoDir);
        _cloudDeviceIds
          ..clear()
          ..addAll(
            list.where((item) => item.isDir).map((item) => item.name),
          );
      }
      // 拷贝快照遍历，避免并发 online 消息修改集合触发并发修改异常。
      final deviceIds = List<String>.from(_cloudDeviceIds);
      for (var devId in deviceIds) {
        if (devId == _selfDevId) {
          continue;
        }
        final dev = await getDeviceInfoFromCloud(devId);
        if (dev == null) {
          logger.warn(tag, 'loadDeviceInfo failed, devId = $devId');
          continue;
        }
        result.add(dev);
      }
    } catch (err, stack) {
      logger.error(tag, err, stack);
    }
    return result;
  }

  Future<Map<String, dynamic>?> _readSyncData(
    String devId,
    String date,
    String id,
    bool loadingMissingData,
  ) async {
    final client = _client;
    if (client == null) {
      logger.warn(tag, '_readSyncData storage client is null');
      return null;
    }
    final dirPath = getHistoryDatePath(devId, date);
    final path = '$dirPath/$id';
    final bytes = await client.readFileBytes(path);
    if (bytes == null) {
      logger.warn(tag, 'read file failed, path = $path');
      return null;
    }
    final syncData = await _syncData(devId, bytes, loadingMissingData);
    if (syncData != null) {
      await _sendOrQueueStorageAck(syncData['id'], devId);
    }
    return syncData;
  }

  Future<Map<String, dynamic>?> _syncData(
    String devId,
    List<int> bytes,
    bool loadingMissingData,
  ) async {
    final device = _deviceState.getStoredById(devId);
    Map<String, dynamic>? result;
    //on sync
    try {
      final data = m2.deserialize(Uint8List.fromList(bytes)) as Map<dynamic, dynamic>;
      final module = Module.getValue((data['module']));
      final map = data.cast<String, dynamic>();
      final opId = _getStorageSyncOpId(map);
      if (opId == null || module == Module.unknown) {
        logger.warn(
          tag,
          'skip storage sync ack because message is not recognizable. '
          "devId=$devId, module=${map["module"]}, id=${map["id"]}",
        );
        return null;
      }
      // 原始同步数据会被 handler 修改，先保留一份用于进度、ACK 和已消费游标。
      final syncData = jsonDecode(jsonEncode(map)) as Map<String, dynamic>;
      try {
        //存储回放与 missingData 载荷同构，统一交给同步分发器解析落库
        final BaseDeviceInfo sender;
        if (device == null) {
          sender = BaseDeviceInfo(
            guid: devId,
            name: '',
            type: _self.type,
          );
        } else {
          sender = BaseDeviceInfo.fromDevice(device);
        }
        final message = MessageData(
          send: sender,
          key: .sync,
          data: map,
        );
        final SyncSource source = loadingMissingData ? .storageMissing : .storage;
        _syncDispatcher.handleSync(message, source: source);
      } catch (err, stack) {
        logger.error(
          tag,
          'storage sync listener process failed. devId=$devId, opId=$opId, err=$err',
          stack,
        );
      } finally {
        // 存储同步收到并识别后即视为已消费，避免幂等跳过的数据下次仍被补拉。
        await _appDb.operationRecordDao.add(storageSyncRecordFromMap(syncData));
      }
      result = syncData;
    } catch (err, stack) {
      logger.error(tag, err, stack);
    }
    return result;
  }

  /// 读取存储同步消息的原始操作 id，只有可定位发送端 OperationRecord 时才确认。
  int? _getStorageSyncOpId(Map<String, dynamic> map) {
    final id = map['id'];
    if (id is int) {
      return id;
    }
    if (id is String) {
      return int.tryParse(id);
    }
    return null;
  }

  //endregion

  //region Upload sync failed data
  Future<void> uploadSyncFailedData() async {
    if (_uploadingSyncFailedData) {
      return;
    }
    final client = _client;
    if (client == null) {
      return;
    }
    _uploadingSyncFailedData = true;
    try {
      final list = await _appDb.operationRecordDao.getStorageSyncFiledData(
        _selfDevId,
      );
      final List<FutureFunction> tasks = [];
      for (var record in list) {
        try {
          //重传前按正常发送路径重建载荷
          final syncData = await _syncPush.buildPayload(record);
          tasks.add(() async {
            final date = DateTime.parse(record.time).format('yyyy-MM-dd');
            final historyDirPath = getHistoryDatePath(_selfDevId, date);
            final id = record.id;
            final path = '$historyDirPath/$id';
            final result = await client.createFile(
              path,
              m2.serialize(syncData.data),
              createDir: true,
            );
            if (!result) {
              return;
            }
            //重传成功后落库与界面刷新顺序执行，避免状态错乱
            _appDb.execSequentially(
              () => _appDb.operationRecordDao.updateStorageSyncStatus(
                id,
                true,
              ),
            );
            final historyId = _historyIdForSync(record);
            if (historyId != null) {
              //仅历史记录在重传成功后更新本地 sync 状态
              _appDb.execSequentially(() async {
                await _appDb.historyDao.setSync(historyId, true);
                final history = await _appDb.historyDao.getById(historyId);
                if (history == null) {
                  return;
                }
                _historyRecorder.emitDelta(
                  HistoryDeltaEvent(
                    history: history.copyWith(sync: true),
                    operation: .update,
                  ),
                );
              });
            }
            // Notify storage peers after retry success so they can load the recovered record.
            final devIds = _deviceState.registry.getDevIdsByStorage();
            logger.info(
              tag,
              'notify storage devices changed. targetCount=${devIds.length}',
            );
            for (final devId in devIds) {
              _wsService.send(
                WsMsgData(WsMsgType.change, '$date:$id', devId),
              );
            }
          });
        } catch (err, stack) {
          logger.error(tag, err, stack);
        }
      }

      await ParallelTask(tasks: tasks, maxParallelCnt: maxParallelCnt).run();
    } finally {
      _uploadingSyncFailedData = false;
    }
  }

  //endregion

  //region Websocket message process

  Future<void> reconnectWs() async {
    if (!_shouldKeepWsConnected()) {
      return;
    }
    await _wsService.reconnect();
  }

  Future<void> disconnectWs() async {
    _heartbeatNotifier.stop(_storageOnlineHeartbeatTaskName);
    _notifyStorageDevicesOfflineBeforeManualDisconnect();
    await _wsService.disconnect();
  }

  void connectDevice(String devId) {
    logger.info(
      tag,
      'send online heartbeat. targetDevId=$devId, trigger=${StorageOnlineHeartbeatTrigger.connectDevice.name}',
    );
    unawaited(
      _sendOnlineHeartbeatToDevice(
        devId,
        trigger: StorageOnlineHeartbeatTrigger.connectDevice,
      ),
    );
  }

  void disconnectDevice(String devId, {bool manual = false}) {
    logger.info(
      tag,
      'send offline. targetDevId=$devId, source=disconnectDevice',
    );
    _wsService.send(WsMsgData(WsMsgType.offline, '', devId));
    _handleDeviceDisconnected(devId, source: 'disconnectDevice', notify: false, manual: manual);
  }

  void _notifyStorageDevicesOfflineBeforeManualDisconnect() {
    final devIds = _deviceState.registry.getDevIdsByStorage();
    logger.info(
      tag,
      'notify storage devices offline before manual disconnect. targetCount=${devIds.length}',
    );
    for (final devId in devIds) {
      _wsService.send(WsMsgData(WsMsgType.offline, '', devId));
    }
  }

  void _disconnectAllStorageDevices({required String source}) {
    final devIds = _deviceState.registry.getDevIdsByStorage();
    logger.info(
      tag,
      'disconnect all storage devices. source=$source, targetCount=${devIds.length}',
    );
    for (final devId in devIds) {
      _handleDeviceDisconnected(devId, source: source, notify: false);
    }
  }

  /// 注册存储在线心跳任务，统一复用传输心跳服务的定时器和屏幕生命周期。
  void _registerStorageOnlineHeartbeatTask() {
    _heartbeatNotifier.registerTask(
      TransportHeartbeatTask(
        name: _storageOnlineHeartbeatTaskName,
        shouldRun: () => _shouldKeepWsConnected() && _wsService.running,
        onTick: (trigger) => _broadcastOnlineHeartbeat(
          trigger: _mapOnlineHeartbeatTrigger(trigger),
        ),
        onStop: (reason) {
          if (reason != TransportHeartbeatStopReason.screenOffAutoClose) {
            return;
          }
          // 息屏自动断开由统一心跳服务触发，避免 Storage 自己再维护一套定时器。
          unawaited(disconnectWs());
        },
      ),
    );
  }

  /// 将通用心跳触发原因转换为存储在线心跳的业务触发原因。
  StorageOnlineHeartbeatTrigger _mapOnlineHeartbeatTrigger(
    TransportHeartbeatTrigger trigger,
  ) {
    switch (trigger) {
      case TransportHeartbeatTrigger.start:
        return StorageOnlineHeartbeatTrigger.wsConnected;
      case TransportHeartbeatTrigger.timer:
        return StorageOnlineHeartbeatTrigger.timer;
      case TransportHeartbeatTrigger.screenOpened:
        return StorageOnlineHeartbeatTrigger.screenOpened;
      case TransportHeartbeatTrigger.manual:
        return StorageOnlineHeartbeatTrigger.manual;
    }
  }

  /// 向所有云端已知设备广播在线心跳，用于弥补单次 online 消息丢失的问题。
  Future<void> _broadcastOnlineHeartbeat({
    required StorageOnlineHeartbeatTrigger trigger,
  }) async {
    final client = _client;
    if (client == null) {
      logger.warn(tag, '_broadcastOnlineHeartbeat storage client is null');
      return;
    }
    // 目标设备集来自启动时缓存 + online 消息增量，避免每 30s 重复列举云端设备目录。
    // 遍历前拷贝快照，防止 await 发送期间收到 online 回调修改集合触发并发修改异常。
    final deviceIds = List.of(_cloudDeviceIds);
    logger.debug(
      tag,
      'broadcast online heartbeat. trigger=${trigger.name}, targetCount=${deviceIds.length}',
    );
    for (var devId in deviceIds) {
      await _sendOnlineHeartbeatToDevice(devId, trigger: trigger);
    }
  }

  /// 向指定设备发送在线心跳，并返回底层 WebSocket 是否已成功入队。
  Future<bool> _sendOnlineHeartbeatToDevice(
    String devId, {
    required StorageOnlineHeartbeatTrigger trigger,
  }) async {
    try {
      final devIds = _deviceState.registry.getDevIdsByStorage();
      if (devIds.isEmpty) {
        //无设备，跳过
        return false;
      }
      final ipList = await _getInterfaceIpList();
      final port = _discoverySettings.port;
      final queued = _wsService.send(
        WsMsgData(
          WsMsgType.online,
          jsonEncode({'ipList': ipList, 'port': port}),
          devId,
        ),
      );
      logger.info(
        tag,
        'send online heartbeat. targetDevId=$devId, trigger=${trigger.name}, queued=$queued, ipCount=${ipList.length}, port=$port',
      );
      return queued;
    } catch (err, stack) {
      logger.error(
        tag,
        'build online heartbeat failed. targetDevId=$devId, trigger=${trigger.name}, error=$err',
        stack,
      );
      return false;
    }
  }

  Future<void> _dispatchWsMessage(WsMsgData msg) async {
    logger.debug(tag, '_onWsMessage ${msg.toJson()}');
    switch (msg.operation) {
      case WsMsgType.online:
        await _processOnlineMsg(msg);
        break;
      case WsMsgType.offline:
        await _processOfflineMsg(msg);
        break;
      case WsMsgType.change:
        await _processChangeMsg(msg);
        break;
      case WsMsgType.syncFile:
        await _processSyncFileMsg(msg);
        break;
      case WsMsgType.appInfo:
        await _processAppInfoMsg(msg);
        break;
      case WsMsgType.ack:
        await _processAckMsg(msg);
        break;
      default:
        logger.error(tag, 'unknown ws data type, content = ${msg.toJson()}');
    }
  }

  Future<void> _onWsConnected() async {
    final versionRequestId = ++_notificationVersionRequestId;
    _appStateNotifier.updateTransportServerVersion('');
    unawaited(_refreshNotificationServerVersion(versionRequestId));
    if (!_loadingMissingData) {
      unawaited(_loadMissingData());
    }
    _heartbeatNotifier.start(_storageOnlineHeartbeatTaskName);
  }

  Future<void> _onWsDisconnected() async {
    _notificationVersionRequestId++;
    _appStateNotifier.updateTransportServerVersion('');
    _disconnectAllStorageDevices(source: 'wsDisconnected');
  }

  /// 通过通知服务的 HTTP 检查接口刷新当前通知服务版本；失败不影响已建立的 WebSocket 连接。
  Future<void> _refreshNotificationServerVersion(int requestId) async {
    try {
      final version = await NotificationServerUtil.getVersion(
        _forwardSettings.notificationServer,
      );
      if (requestId != _notificationVersionRequestId) {
        return;
      }
      _appStateNotifier.updateTransportServerVersion(version);
    } catch (err, stack) {
      logger.error(
        tag,
        'refresh notification server version failed: $err',
        stack,
      );
    }
  }

  void _onWsStatusChanged(StorageWsStatus status) {
    switch (status) {
      case StorageWsStatus.connecting:
        _updateForwardStatus(ForwardServerStatus.connecting);
        break;
      case StorageWsStatus.connected:
        _updateForwardStatus(ForwardServerStatus.connected);
        break;
      case StorageWsStatus.disconnected:
        _updateForwardStatus(ForwardServerStatus.disconnected);
        break;
    }
  }

  ///执行设备连接操作（SocketService设备发现时不能执行）
  Future<bool> _connectDevices() async {
    if (_client == null) {
      logger.warn(tag, '_connectDevices storage client is null');
      return false;
    }
    final discoveryState = ref.read(discoveryProvider);
    if (discoveryState) {
      //正在设备发现，不能执行
      logger.warn(tag, 'SocketService discovering');
      return false;
    }
    //获取已配对且离线的设备
    var offlineAndPairedList = _deviceState.offlineAndPairedList.map((item) => item.guid).toSet();
    //执行连接操作
    for (var devId in offlineAndPairedList) {
      if (_isConnected(devId)) {
        logger.debug(
          tag,
          'send online heartbeat for offline paired device. targetDevId=$devId',
        );
        await _sendOnlineHeartbeatToDevice(
          devId,
          trigger: StorageOnlineHeartbeatTrigger.connectDevices,
        );
      } else {
        logger.debug(
          tag,
          'reconnect device after online heartbeat. targetDevId=$devId',
        );
        await _connectDevice(devId);
      }
    }
    return true;
  }

  bool _isConnected(String devId) {
    return _deviceState.registry.getProtocol(devId) != null;
  }

  Future<void> _connectDevice(String devId) async {
    if (_client == null) {
      logger.warn(tag, '_connectDevice storage client is null');
      return;
    }
    final device = await getDeviceInfoFromCloud(devId);
    final version = await getDeviceVersionInfoFromCloud(devId);
    final minVersion = await getDeviceMinVersionInfoFromCloud(devId);
    if (device == null) {
      logger.warn(tag, 'device is null, target dev id = $devId');
      return;
    }
    if (version == null) {
      logger.warn(tag, 'version is null, target dev id = $devId');
      return;
    }
    if (minVersion == null) {
      logger.warn(tag, 'minVersion is null, target dev id = $devId');
      return;
    }
    final isSocket = _deviceState.registry.getProtocol(device.guid)?.isSocket ?? false;
    if (isSocket) {
      logger.warn(tag, '已通过Socket协议连接: ${device.guid}');
      return;
    }
    final result = await _addOrUpdateDevice(device);
    logger.debug(
      tag,
      'send online heartbeat after connect device. targetDevId=$devId',
    );
    await _sendOnlineHeartbeatToDevice(
      devId,
      trigger: StorageOnlineHeartbeatTrigger.connectDeviceInternal,
    );
    if (!result) {
      logger.warn(tag, 'add or update device failed, device = $device');
    }
  }

  // 处理设备连接信息
  // 这里只是记录设备连接状态，按照优先级内网>外网
  // 先等待 socketService 设备发现流程结束，再调用存储服务的设备连接
  Future<void> _processOnlineMsg(WsMsgData msg) async {
    final devId = msg.targetDevId;
    if (devId == _selfDevId) {
      return;
    }
    final discoveryState = ref.read(discoveryProvider);
    if (discoveryState) {
      // Socket 发现期间不触发 Storage 连接；online 是周期心跳，下一次心跳会继续兜底处理。
      logger.debug(tag, 'socket discovering');
      return;
    }
    // 在线设备 id 增量入缓存，让心跳广播覆盖启动之后新出现/新上线的设备。
    _cloudDeviceIds.add(devId);
    //已经连接，跳过
    final alreadyConnected = _isConnected(devId);
    // 探活失败即视为 socket 掉线，后续直接走存储接管，不依赖 UI 在线列表判断。
    var socketDied = false;
    if (alreadyConnected) {
      final isSocket = _deviceState.registry.getProtocol(devId)?.isSocket ?? false;
      if (isSocket) {
        //当网络环境切换，socket可能存在假连接现象，这里通过测试响应判断是否是真连接
        final online = await ref
            .read(sessionProvider.notifier)
            .testIsOnline(
              devId,
              autoReconnect: false,
            );
        if (online) {
          logger.debug(tag, 'connected, skip');
          return;
        }
        socketDied = true;
      }
    }
    if (!alreadyConnected) {
      // 仅在设备从未注册或断线后重新上线时补发 pending ACK。
      unawaited(_retryPendingAcksForDevice(devId));
    }
    var diffNetwork = true;
    if (msg.data.isNotNullAndEmpty) {
      try {
        final json = jsonDecode(msg.data);
        final ipList = (json['ipList'] as List<dynamic>).cast();
        final port = json['port'] as int;
        for (var ip in ipList) {
          try {
            await Socket.connect(ip, port, timeout: 500.ms);
            diffNetwork = false;
            //与目标设备同一网络，跳过
            break;
          } catch (err) {
            //ignore
          }
        }
      } catch (err, stack) {
        logger.error(tag, err, stack);
      }
    }

    if (!diffNetwork) {
      // 同网段优先让 Socket 接管；若短暂等待后 Socket 未建连，再用存储通道兜底更新在线状态。
      unawaited(
        _fallbackConnectStorageDeviceAfterSocketGracePeriod(msg.targetDevId),
      );
      return;
    }
    // socket 探活失败或从未注册时直接走存储接管，避免依赖 UI 列表的异步竞态。
    if (socketDied || !alreadyConnected) {
      await _connectDevice(msg.targetDevId);
    }
    // 仅当设备由离线转为在线（真正重连）时才补拉缺失数据；
    // 持续在线的设备依赖 change 消息增量同步，避免每次 online 心跳都触发全量扫描。
    if (!alreadyConnected && !_loadingMissingData) {
      // 对端重连后主动补拉其离线期间写入的历史，避免只依赖 change 事件导致漏同步。
      unawaited(_reloadMissingDataForDevice(msg.targetDevId));
    }
  }

  /// 同网段 online 先等待 Socket 接管；若等待后仍未在线，则回退到存储通道连接。
  Future<void> _fallbackConnectStorageDeviceAfterSocketGracePeriod(
    String devId,
  ) async {
    await Future<void>.delayed(_sameNetworkSocketGracePeriod);
    final isSocketConnected = _deviceState.registry.getProtocol(devId)?.isSocket ?? false;
    if (isSocketConnected) {
      return;
    }
    // 此时 socket 已确认未连接，若注册表仍持有该设备则说明已有其他通道接管，跳过。
    if (_isConnected(devId)) {
      return;
    }
    logger.debug(
      tag,
      'fallback connect storage device after socket grace period. targetDevId=$devId',
    );
    await _connectDevice(devId);
  }

  /// 对单个重连设备执行一次缺失数据补拉，复用全量补拉的筛选与读取逻辑。
  Future<void> _reloadMissingDataForDevice(String devId) async {
    final client = _client;
    if (client == null) {
      logger.warn(tag, '_reloadMissingDataForDevice storage client is null');
      return;
    }
    if (!_syncSettings.autoSyncMissingData) {
      logger.warn(tag, 'autoSyncMissingData is false');
      return;
    }
    if (_loadingMissingData) {
      return;
    }
    // 心跳节流：同设备距上次补拉过近则跳过，作为“仅真重连才补拉”之外的并发兜底。
    final now = DateTime.now();
    final lastReload = _lastReloadAt[devId];
    if (lastReload != null && now.difference(lastReload) < _reloadMissingCoolDown) {
      return;
    }
    _lastReloadAt[devId] = now;
    _loadingMissingData = true;
    try {
      final clientType = client.runtimeType;

      void checkClientRuntimeType() {
        final currentType = _client?.runtimeType;
        if (clientType != currentType) {
          throw DifferentStorageClientTypeException(
            'current storage client($currentType) is not a $clientType',
          );
        }
      }

      await _syncMissingDataForDevices(
        devIds: <String>[devId],
        client: client,
        checkClientRuntimeType: checkClientRuntimeType,
      );
    } finally {
      _loadingMissingData = false;
    }
  }

  Future<void> _processOfflineMsg(WsMsgData msg) async {
    final targetDevId = msg.targetDevId;
    logger.debug(tag, 'receive offline. targetDevId=$targetDevId');
    _handleDeviceDisconnected(targetDevId, source: 'offlineMessage');
  }

  Future<void> _processChangeMsg(WsMsgData msg) async {
    if (_client == null) {
      logger.warn(tag, '_processChangeMsg storage client is null');
      return;
    }
    final [date, id] = msg.data.split(':');
    await _readSyncData(msg.targetDevId, date, id, false);
  }

  Future<void> _processAckMsg(WsMsgData msg) async {
    try {
      final data = (jsonDecode(msg.data) as Map<dynamic, dynamic>).cast<String, dynamic>();
      final opId = data['opId'] as int;
      final devId = data['devId'] as String;
      await _appDb.operationSyncDao.add(newOperationSync(opId: opId, devId: devId));
    } catch (err, stack) {
      logger.error(
        tag,
        'process storage ack failed. msg=${msg.toJson()}, err=$err',
        stack,
      );
    }
  }

  Future<void> _sendOrQueueStorageAck(dynamic opId, String targetDevId) async {
    if (opId is! int) {
      logger.warn(
        tag,
        'storage ack opId invalid. opId=$opId, targetDevId=$targetDevId',
      );
      return;
    }
    if (!_isConnected(targetDevId)) {
      await _appDb.pendingStorageAckDao.add(
        PendingStorageAck(opId: opId, targetDevId: targetDevId),
      );
      return;
    }
    final sent = _sendStorageAck(opId, targetDevId);
    if (sent) {
      return;
    }
    await _appDb.pendingStorageAckDao.add(
      PendingStorageAck(opId: opId, targetDevId: targetDevId),
    );
  }

  bool _sendStorageAck(int opId, String targetDevId) {
    return _wsService.send(
      WsMsgData(
        WsMsgType.ack,
        jsonEncode({'opId': opId, 'devId': _selfDevId}),
        targetDevId,
      ),
    );
  }

  Future<void> _retryPendingAcksForDevice(String targetDevId) async {
    final list = await _appDb.pendingStorageAckDao.getByTargetDevId(
      targetDevId,
    );
    for (final ack in list) {
      if (_sendStorageAck(ack.opId, targetDevId)) {
        await _appDb.pendingStorageAckDao.removeByKey(ack.opId, targetDevId);
      }
    }
  }

  /// 处理对端存储中转文件就绪通知：按通知中的日期与文件 id 下载并走统一收尾
  Future<void> _processSyncFileMsg(WsMsgData msg) async {
    final client = _client;
    if (client == null) {
      logger.warn(tag, '_processSyncFileMsg storage client is null');
      return;
    }
    final [dateStr, fromDevId, idStr] = msg.data.split(':');
    final datePath = getHistoryDatePath(fromDevId, dateStr);
    try {
      await _fileReceiver.receiveFromStorage(
        client: client,
        datePath: datePath,
        fromDevId: fromDevId,
        fileId: idStr.toInt(),
      );
    } catch (err, stack) {
      logger.error(tag, 'receive storage file failed. data=${msg.data}', stack);
    }
  }

  Future<void> _processAppInfoMsg(WsMsgData msg) async {
    final client = _client;
    if (client == null) {
      logger.warn(tag, '_processAppInfoMsg storage client is null');
      return;
    }
    final id = msg.data;
    var dirPath = getAppInfoDirectoryPath(msg.targetDevId);
    var filePath = '$dirPath/$id';
    var bytes = await client.readFileBytes(filePath);
    if (bytes == null) {
      logger.warn(tag, 'read file failed, path = $filePath');
      return;
    }
    final syncData = await _syncData(msg.targetDevId, bytes, false);
    if (syncData != null) {
      // appInfo 的 websocket 通知只带 appInfo.id，ACK 需要使用文件内容里的操作记录 id。
      await _sendOrQueueStorageAck(syncData['id'], msg.targetDevId);
    }
  }

  Future<bool> _addOrUpdateDevice(Device dev) async {
    final dbDev = await _appDb.deviceDao.getById(dev.guid);
    final isWebDAV = _client is WebDAVClient;
    final protocol = isWebDAV ? TransportProtocol.webdav : TransportProtocol.s3;
    final currentProtocol = _deviceState.registry.getProtocol(dev.guid);
    if (currentProtocol?.isSocket ?? false) {
      // Socket 在线时不允许存储连接覆盖页面和注册表里的实时协议状态。
      logger.debug(
        tag,
        'skip storage device update because socket is connected. targetDevId=${dev.guid}',
      );
      return false;
    }
    final address = protocol.name;
    final result = (dbDev ?? dev).copyWith(address: Value(address));
    final confirmResult = await _deviceNotifier.confirmPairingState(
      device: result,
      localIsPaired: true,
      remoteIsPaired: true,
      protocol: protocol,
    );
    final success = confirmResult.accepted;
    if (!success) {
      logger.debug(tag, 'confirmResult false');
      return false;
    }
    try {
      final devId = result.guid;
      final device = await getDeviceInfoFromCloud(devId);
      final version = await getDeviceVersionInfoFromCloud(devId);
      final minVersion = await getDeviceMinVersionInfoFromCloud(devId);
      if (device == null) {
        logger.warn(tag, 'device is null, target dev id = $devId');
        return success;
      }
      if (version == null) {
        logger.warn(tag, 'version is null, target dev id = $devId');
        return success;
      }
      if (minVersion == null) {
        logger.warn(tag, 'minVersion is null, target dev id = $devId');
        return success;
      }
      _deviceNotifier.emitLifecycleEvent(
        DeviceConnected(
          device: BaseDeviceInfo.fromDevice(device),
          minVersion: minVersion,
          version: version,
          protocol: protocol,
        ),
      );
      _deviceState.registry.addDevice(
        BaseDeviceInfo.fromDevice(device),
        protocol,
        version,
        minVersion,
      );
      // 存储接管后取消同设备 socket 重连循环，避免继续空转重试。
      _reconnect.cancelReconnect(devId);
    } catch (err, stack) {
      logger.error(tag, err, stack);
    }
    return true;
  }

  //endregion

  //region Update server status
  /// 统一向所有观察方广播状态，减少内部样板和状态命名分叉。
  void _updateForwardStatus(ForwardServerStatus status) {
    final eventNotifier = ref.read(forwardStatusEventProvider.notifier);
    eventNotifier.emit(status);
  }

  //endregion

  //region Send data

  Future<void> storeData(MsgType key, Map<String, dynamic> data, [BaseDeviceInfo? device]) async {
    var id = data['id'];
    if (_client == null) {
      logger.warn(tag, 'sendData storage client is null');
      //写入存储服务，更新操作记录
      //仅有少数几个key通过存储服务中转
      if (MsgType.storageServiceKeys.contains(key)) {
        await _appDb.operationRecordDao.updateStorageSyncStatus(id, false);
      }
      return;
    }
    //仅有少数几个key通过存储服务中转
    if (!MsgType.storageServiceKeys.contains(key)) {
      return;
    }
    final today = DateTime.now().format('yyyy-MM-dd');
    //sync file
    if (key == MsgType.file) {
      if (device == null) {
        logger.warn(tag, 'storeData file requires target device');
        return;
      }
      await _sendRoutedFile(device, data);
    } else {
      //获取module，根据 module 处理
      final module = Module.getValue(data['module']);
      if (module == Module.appInfo) {
        // Upload appInfo first so notification/history records never arrive before their source data.
        await _uploadAppInfo(AppInfo.fromJson(jsonDecode(data['data'])));
      }
      // 缓存数据，避免批量发送重复写入
      final cacheKey = _buildCacheKey(data);
      final hasData = _cache.contains(cacheKey);
      if (!hasData) {
        _cache.add(cacheKey);
        //缓存 10s
        Future.delayed(10.s, () => _cache.remove(cacheKey));
      }
      await _storeHistory(id, device, key, today, data, hasData);
    }
  }

  @override
  Future<void> sendData(BaseDeviceInfo device, MsgType key, Map<String, dynamic> data, [bool onlyPaired = true]) async {
    return storeData(key, data, device);
  }

  ///从存储服务删除记录
  Future<void> deleteOpRecords(List<OperationRecord> records) async {
    final client = _client;
    if (client == null) {
      logger.warn(tag, 'deleteOpRecords storage client is null');
      return;
    }
    for (var record in records) {
      final dir = getHistoryDatePath(
        _selfDevId,
        DateTime.parse(record.time).format('yyyy-MM-dd'),
      );
      client.deleteFile('$dir/${record.id}');
    }
  }

  //region Send file

  /// 通过存储中转上传文件并通知对端下载；由文件发送调度与消息路由共同调用
  Future<void> sendFile(FileSendJob job) async {
    final client = _client;
    if (client == null) {
      logger.warn(tag, 'sendFile storage client is null');
      throw Exception('storage client is null');
    }
    final appPaths = await ref.read(appPathsProvider.future);
    final channel = StorageSendChannel(
      client: client,
      wsService: _wsService,
      selfDevId: _selfDevId,
      cachePath: appPaths.cachePath,
      buildDatePath: getHistoryDatePath,
    );
    await channel.send(job);
  }

  /// 将消息路由进入的文件数据组装为发送任务并上传
  Future<void> _sendRoutedFile(BaseDeviceInfo device, Map<String, dynamic> data) async {
    final fileName = data['fileName'] as String;
    final job = FileSendJob(
      device: device,
      task: FileTransferTask(
        id: const Uuid().v4(),
        direction: .send,
        devId: device.guid,
        devName: device.name,
        fileName: fileName,
        localPath: data['filePath'] as String,
        isUri: (data['isUri'] as bool?) ?? false,
        totalSize: (data['size'] as num).toInt(),
        fileId: (data['fileId'] as num).toInt(),
        groupKey: parseProtocolFileGroupKey(fileName),
      ),
      cancelToken: CancelToken.none,
      onProgress: (_) {},
    );
    await sendFile(job);
  }

  //endregion

  //region Send history
  Future<void> _storeHistory(int id, BaseDeviceInfo? dev, MsgType key, String today, Map<String, dynamic> data, bool hasData) async {
    final client = _client;
    if (client == null) {
      logger.warn(tag, '_sendHistory storage client is null');
      return;
    }
    if (!hasData) {
      //写入存储服务
      final historyDirPath = getHistoryDatePath(_selfDevId, today);
      final path = '$historyDirPath/$id';
      final result = await client.createFile(
        path,
        m2.serialize(data),
        createDir: true,
      );
      //写入存储服务，更新操作记录
      _appDb.operationRecordDao.updateStorageSyncStatus(id, result);
      if (!result) {
        logger.warn(
          tag,
          'StorageService write data failed! key=${key.name}, data = ${jsonEncode(data)}',
        );
        return;
      }
    }
    // notify
    if (dev != null) {
      logger.warn(tag, 'notify on changed, dev = ${dev.name}(${dev.guid})');
      _wsService.send(WsMsgData(WsMsgType.change, '$today:$id', dev.guid));
    } else {
      logger.warn(tag, 'notify canceled: dev is null');
    }
  }

  //endregion

  //region Path getter

  String getDeviceInfoPath(String devId) {
    return '$devicesInfoDir/$devId/deviceInfo.json';
  }

  String getDeviceVersionPath(String devId) {
    return '$devicesInfoDir/$devId/version.json';
  }

  String getDeviceMinVersionPath(String devId) {
    return '$devicesInfoDir/$devId/minVersion.json';
  }

  String getHistoryDatePath(String devId, String date) {
    return '$historyDir/$devId/$date';
  }

  String getHistoryDirectoryPath(String devId) {
    return '$historyDir/$devId';
  }

  String getAppInfoDirectoryPath(String devId) {
    return '$appInfoDir/$devId';
  }

  String _buildCacheKey(Map<String, dynamic> data) {
    return jsonEncode(data);
  }

  //endregion

  //region BaseInfo getter

  Future<Device?> getDeviceInfoFromCloud(String devId) async {
    final bytes = await _client?.readFileBytes(getDeviceInfoPath(devId));
    if (bytes == null) return null;
    return Device.fromJson(
      (jsonDecode(utf8.decode(bytes)) as Map<dynamic, dynamic>).cast(),
    );
  }

  Future<AppVersion?> getDeviceVersionInfoFromCloud(String devId) async {
    final bytes = await _client?.readFileBytes(getDeviceVersionPath(devId));
    if (bytes == null) return null;
    return AppVersion.fromJson(
      (jsonDecode(utf8.decode(bytes)) as Map<dynamic, dynamic>).cast(),
    );
  }

  Future<AppVersion?> getDeviceMinVersionInfoFromCloud(String devId) async {
    final bytes = await _client?.readFileBytes(getDeviceMinVersionPath(devId));
    if (bytes == null) return null;
    return AppVersion.fromJson(
      (jsonDecode(utf8.decode(bytes)) as Map<dynamic, dynamic>).cast(),
    );
  }

  ///发现轮次结束后尝试与云端在线设备建立存储连接
  void _onDiscoveryEvent(DeviceDiscoveryEvent event) {
    if (event is DeviceDiscoveryFinished) {
      _connectDevices();
    }
  }

  //endregion

  ///获取所有网卡 ip
  Future<List<String>> _getInterfaceIpList() async {
    final interfaces = await NetworkUtil.listInterfaces();
    var expendAddress = interfaces.map((networkInterface) => networkInterface.addresses).expand((ip) => ip);
    return expendAddress.where((ip) => ip.type == InternetAddressType.IPv4).map((address) => address.address).toList();
  }

  /// 统一处理设备离线时的本地状态收口，避免注册表和监听器状态漂移。
  void _handleDeviceDisconnected(
    String devId, {
    required String source,
    bool notify = true,
    bool manual = false,
  }) {
    final currentProtocol = _deviceState.registry.getProtocol(devId);
    final existedInRegistry = currentProtocol != null;
    if (currentProtocol?.isSocket ?? false) {
      // 存储 offline 只代表存储通道离线，不能清理仍然存活的 Socket 连接。
      logger.debug(
        tag,
        'ignore storage disconnect for socket device. targetDevId=$devId, source=$source, protocol=${currentProtocol!.name}',
      );
      return;
    }

    final shouldNotify = notify && existedInRegistry;
    if (existedInRegistry) {
      _deviceState.registry.removeDevice(devId);
    }
    logger.debug(
      tag,
      'cleanup disconnected device. targetDevId=$devId, source=$source, removedRegistry=$existedInRegistry',
    );
    _deviceNotifier.emitLifecycleEvent(DeviceDisconnected(devId, manual: manual, notify: shouldNotify));
  }

  /// 只有历史记录重传成功后，才需要回写 history 表的 sync 状态。
  static int? _historyIdForSync(OperationRecord record) {
    if (record.module != Module.history) {
      return null;
    }
    return int.tryParse(record.data);
  }
}

/// 存储在线心跳触发原因，用于区分连接建立、定时心跳、亮屏恢复和手动连接等入口。
enum StorageOnlineHeartbeatTrigger {
  wsConnected,
  timer,
  screenOpened,
  manual,
  connectDevice,
  connectDevices,
  connectDeviceInternal,
}
