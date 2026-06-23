import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:clipshare/app/data/enums/history_content_type.dart';
import 'package:clipshare/app/data/enums/module.dart';
import 'package:clipshare/app/data/enums/msg_type.dart';
import 'package:clipshare/app/data/enums/obj_storage_type.dart';
import 'package:clipshare/app/data/enums/op_method.dart';
import 'package:clipshare/app/data/enums/syncing_file_state.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/enums/transport_protocol.dart';
import 'package:clipshare/app/data/models/dev_info.dart';
import 'package:clipshare/app/data/models/storage/s3_config.dart';
import 'package:clipshare/app/data/models/syncing_file.dart';
import 'package:clipshare/app/data/models/version.dart';
import 'package:clipshare/app/data/models/storage/web_dav_config.dart';
import 'package:clipshare/app/data/models/websocket/ws_msg_data.dart';
import 'package:clipshare/app/data/models/websocket/ws_msg_type.dart';
import 'package:clipshare/app/data/repository/entity/tables/app_info.dart';
import 'package:clipshare/app/data/repository/entity/tables/device.dart';
import 'package:clipshare/app/data/repository/entity/tables/history.dart';
import 'package:clipshare/app/data/repository/entity/tables/operation_record.dart';
import 'package:clipshare/app/exceptions/different_storage_client_type_exception.dart';
import 'package:clipshare/app/handlers/storage/aliyun_oss_client.dart';
import 'package:clipshare/app/handlers/storage/s3_client.dart';
import 'package:clipshare/app/handlers/storage/storage_client.dart';
import 'package:clipshare/app/handlers/sync/abstract_data_sender.dart';
import 'package:clipshare/app/handlers/storage/web_dav_client.dart';
import 'package:clipshare/app/handlers/sync/missing_data_sync_handler.dart';
import 'package:clipshare/app/listeners/dev_alive_listener.dart';
import 'package:clipshare/app/listeners/discover_listener.dart';
import 'package:clipshare/app/listeners/forward_status_listener.dart';
import 'package:clipshare/app/modules/device_module/device_controller.dart';
import 'package:clipshare/app/modules/history_module/history_controller.dart';
import 'package:clipshare/app/services/clipboard_source_service.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/services/device_service.dart';
import 'package:clipshare/app/services/history_sync_progress_service.dart';
import 'package:clipshare/app/services/syncing_file_progress_service.dart';
import 'package:clipshare/app/services/transport/connection_registry_service.dart';
import 'package:clipshare/app/services/transport/socket_service.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/crypto.dart';
import 'package:clipshare/app/utils/extensions/device_extension.dart';
import 'package:clipshare/app/utils/extensions/number_extension.dart';
import 'package:clipshare/app/utils/extensions/string_extension.dart';
import 'package:clipshare/app/utils/extensions/time_extension.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:clipshare/app/utils/network_interface_filter_util.dart';
import 'package:clipshare/app/utils/parallerl_task.dart';
import 'package:get/get.dart';
import "package:msgpack_dart/msgpack_dart.dart" as m2;
import 'package:uri_file_reader/uri_file_reader.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class _StorageWsRuntimeState {
  bool _started = false;
  int? _activeSessionId;
  int _sessionSeed = 0;

  bool get started => _started;

  void start() {
    _started = true;
  }

  void stop() {
    _started = false;
    _activeSessionId = null;
  }

  int activateNextSession() {
    final sessionId = ++_sessionSeed;
    _activeSessionId = sessionId;
    return sessionId;
  }

  void clearActiveSession([int? sessionId]) {
    if (sessionId == null || _activeSessionId == sessionId) {
      _activeSessionId = null;
    }
  }

  bool isActiveSession(int sessionId) {
    return _activeSessionId == sessionId;
  }

  bool shouldKeepWsConnected({required bool featureEnabled}) {
    return _started && featureEnabled;
  }

  bool shouldHandleDisconnect({
    required int disconnectedSession,
    required bool featureEnabled,
  }) {
    return shouldKeepWsConnected(featureEnabled: featureEnabled) && isActiveSession(disconnectedSession);
  }
}

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
class StorageService extends GetxService with DataSender implements DiscoverListener {
  static const tag = "StorageService";
  final appConfig = Get.find<ConfigService>();
  final dbService = Get.find<DbService>();
  final connRegService = Get.find<ConnectionRegistryService>();
  final historySyncProgressService = Get.find<HistorySyncProgressService>();
  final _connectedDevIds = <String>{};
  static const devicesInfoDir = "devices-info";
  static const historyDir = "history";
  static const appInfoDir = "app-info";
  static const maxParallelCnt = 10;
  static const _baseDirs = [devicesInfoDir, historyDir, appInfoDir];

  String get _selfDevId => appConfig.device.guid;
  var _lastDate = '';
  var _lastDateFilePath = '';
  final _cache = <String>{};
  var _loadingMissingData = false;
  var _uploadingSyncFailedData = false;
  var _wsReconnectScheduled = false;
  final _wsRuntimeState = _StorageWsRuntimeState();

  bool get running => _wsRuntimeState.started;

  //websocket heartbeat
  Timer? _wsPingTimer;

  //region dev registry
  final DeviceConnectionRegistry _registry;

  List<DevAliveListener> get _devAliveListeners => _registry.devAliveListeners;

  List<ForwardStatusListener> get _forwardStatusListener => _registry.forwardStatusListener;

  //endregion

  StorageClient? _client;
  WebSocketChannel? _wsChannel;

  StorageService(this._registry);

  WebDAVConfig? get _webDAVConfig => appConfig.webDAVConfig;

  S3Config? get _s3Config => appConfig.s3Config;

  //region Init

  Future<bool> _createBaseDirectories() async {
    if (_client == null) return false;
    var result = true;
    final selfDevId = _selfDevId;
    final dirs = [..._baseDirs];
    final today = DateTime.now().format("yyyy-MM-dd");
    if (today != _lastDate) {
      _lastDate = today;
      dirs.add(getHistoryDatePath(selfDevId, today));
    }
    for (var dirPath in dirs) {
      final created = await _client?.createDirectory(dirPath) ?? false;
      if (!created) {
        logger.debug(tag, "Create Directory failed: $dirPath");
        return false;
      }
    }
    return result;
  }

  Future<void> _updateBaseInfo() async {
    final client = _client;
    if (client == null) {
      logger.warn(tag, "storage client is null");
      return;
    }
    final device = appConfig.device.copyWith(customName: appConfig.localName);
    await client.createFile(getDeviceInfoPath(_selfDevId), utf8.encode(jsonEncode(device)));
    await client.createFile(getDeviceVersionPath(_selfDevId), utf8.encode(jsonEncode(appConfig.version)));
    await client.createFile(getDeviceMinVersionPath(_selfDevId), utf8.encode(jsonEncode(appConfig.minVersion)));
  }

  /// 检查并上传缺失的本机app信息
  Future<void> _checkAndUploadLocalAppInfo() async {
    final client = _client;
    if (client == null) {
      logger.warn(tag, "storage client is null");
      return;
    }
    final dirPath = getAppInfoDirectoryPath(_selfDevId);
    var result = await client.createDirectory(dirPath);
    if (!result) {
      logger.debug(tag, "checkAndUploadLocalAppInfo failed");
      return;
    }
    final sourceService = Get.find<ClipboardSourceService>();
    var list = sourceService.appInfos.where((item) => item.devId == _selfDevId).toList();
    final existsIds = (await client.list(path: dirPath)).map((item) => item.name).toSet();
    list = list.where((item) => !existsIds.contains(item.id.toString())).toList();
    for (var appInfo in list) {
      if (!await _uploadAppInfo(appInfo)) {
        continue;
      }
    }
  }

  Future<bool> _uploadAppInfo(AppInfo appInfo) async {
    final dirPath = getAppInfoDirectoryPath(_selfDevId);
    if (!await _client!.createDirectory(dirPath)) {
      logger.debug(tag, "_uploadAppInfo createDirectory $dirPath failed.");
      return false;
    }
    final opRecord = OperationRecord.fromSimple(
      Module.appInfo,
      OpMethod.add,
      appInfo.id.toString(),
    );
    final result = await MissingDataSyncHandler.process(opRecord);
    final id = appInfo.id;
    final path = "$dirPath/$id";
    final success = await _client!.createFile(path, m2.serialize(result.result));
    if (!success) {
      logger.warn(tag, "upload appInfo($id) failed");
      return false;
    }
    //ws send
    final devController = Get.find<DeviceController>();
    for (var dev in devController.onlineAndPairedList) {
      _wsChannel?.sink.add(WsMsgData(WsMsgType.appInfo, id.toString(), dev.guid).toString());
    }
    return true;
  }

  /// 检查并下载缺失的其他设备的app信息
  Future<void> _checkAndDownloadMissingAppInfo(String devId) async {
    if (_client == null) {
      logger.warn(tag, "storage client is null");
      return;
    }
    final dirPath = getAppInfoDirectoryPath(devId);
    final sourceService = Get.find<ClipboardSourceService>();
    final list = await _client!.list(path: dirPath);
    final cloudIds = list.where((item) => !item.isDir).map((item) => item.name).toSet();
    final existsIds = sourceService.appInfos.where((item) => item.devId == devId).map((item) => item.id.toString()).toSet();
    final diff = cloudIds.difference(existsIds);
    for (var id in diff) {
      try {
        await _processAppInfoMsg(WsMsgData(WsMsgType.appInfo, id, devId));
      } catch (err, stack) {
        logger.error(tag, "_checkAndDownloadMissingAppInfo error: $err", stack);
      }
    }
  }

  //endregion

  Future<void> start() async {
    _wsRuntimeState.start();
    if (!appConfig.enableStorageSync) {
      _wsRuntimeState.stop();
      return;
    }
    if (!appConfig.enableForward) {
      _wsRuntimeState.stop();
      return;
    }
    connRegService.addDiscoverListener(this);
    if (appConfig.enableS3 && _s3Config != null) {
      if (_s3Config!.type == ObjStorageType.aliyunOss) {
        _client = AliyunOssClient(_s3Config!);
      } else {
        _client = S3Client(_s3Config!);
      }
    } else if (appConfig.enableWebDAV && _webDAVConfig != null) {
      _client = WebDAVClient(_webDAVConfig!);
    } else {
      throw 'storage service config is null';
    }
    _updateForwardConnectingStatus();
    if (!await _createBaseDirectories()) {
      logger.warn(tag, "create base directories failed!");
      _client = null;
      _wsRuntimeState.stop();
      _updateForwardDisConnectedStatus();
      return;
    }
    try {
      await _updateBaseInfo();
      await _checkAndUploadLocalAppInfo();
      uploadSyncFailedData();
      _loadMissingData();
      connectWs();
    } catch (err, stack) {
      logger.error(tag, err, stack);
      _wsRuntimeState.stop();
      _updateForwardDisConnectedStatus();
    }
  }

  Future<void> stop() async {
    _wsRuntimeState.stop();
    _client = null;
    connRegService.removeDiscoverListener(this);
    await disconnectWs();
  }

  Future<void> restart() async {
    await stop();
    await start();
  }

  //region Load missing data

  Future<void> _loadMissingData() async {
    final client = _client;
    if (client == null) {
      logger.warn(tag, "storage client is null");
      return;
    }
    if (!appConfig.autoSyncMissingData) {
      logger.warn(tag, "autoSyncMissingData is false");
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
          throw DifferentStorageClientTypeException('current storage client($currentType) is not a $clientType');
        }
      }

      final devices = await _loadDeviceInfosFromStorage();
      if (devices.isEmpty) {
        logger.warn(tag, "storage devices is empty");
        return;
      }

      //add or update devices
      for (var dev in devices) {
        checkClientRuntimeType();
        await _addOrUpdateDevice(dev);
      }

      final devIds = devices.map((item) => item.guid).toList();
      final devHistoryDirMap = await _loadDevHistoryDirectoriesFromStorage(devIds);

      // sync item : devId -> (date -> id)
      final syncMap = <String, Map<String, List<String>>>{};
      var totalSyncCnt = 0;
      var syncedCnt = 0;

      //region load sync map
      for (var devId in devHistoryDirMap.keys) {
        await _checkAndDownloadMissingAppInfo(devId);
        // load latest record info form db
        final latestRecord = await dbService.opRecordDao.getLatestStorageSyncSuccessByDevId(devId);
        final latestDate = DateTime.parse(latestRecord?.time ?? "1970-01-01");
        final latestId = latestRecord?.id ?? 0;
        final devDateSyncMap = <String, List<String>>{};
        syncMap[devId] = devDateSyncMap;
        var historyDates = devHistoryDirMap[devId]!;
        for (var date in historyDates) {
          // filter date
          if (DateTime.parse(date).isBefore(latestDate.date)) {
            continue;
          }
          final syncIds = <String>[];
          devDateSyncMap[date] = syncIds;
          try {
            final path = getHistoryDatePath(devId, date);
            final items = await client.list(path: path);
            //filter id
            final ids = items.where((item) => !item.isDir).map((item) => item.name).where((id) => int.parse(id) > latestId).toList();
            ids.sort((a, b) => int.parse(b) - int.parse(a));
            totalSyncCnt += ids.length;
            for (var id in ids) {
              checkClientRuntimeType();
              syncIds.add(id);
            }
          } catch (err, stack) {
            logger.error(tag, "loadMissingData error: $err", stack);
          }
        }
      }
      //endregion

      final List<FutureFunction> tasks = [];
      //region load missing data file
      for (var devId in syncMap.keys) {
        final devDateSyncMap = syncMap[devId]!;
        for (var date in devDateSyncMap.keys) {
          final syncIds = devDateSyncMap[date]!;
          for (var id in syncIds) {
            tasks.add(() async {
              Map<String, dynamic>? syncData;
              try {
                checkClientRuntimeType();
                syncData = await _readSyncData(devId, date, id, true);
              } catch (err, stack) {
                if (err is DifferentStorageClientTypeException) {
                  return;
                }
                logger.error(tag, "load missing data file from storage failed! devId = $devId, date = $date, id = $id", stack);
              } finally {
                historySyncProgressService.addProgress(devId, syncData, ++syncedCnt, totalSyncCnt, true);
              }
            });
          }
        }
      }
      //endregion

      await ParallelTask(tasks: tasks, maxParallelCnt: maxParallelCnt).run();
    } finally {
      // Always release the guard so reconnects can retry missing-data sync.
      _loadingMissingData = false;
    }
  }

  Future<Map<String, List<String>>> _loadDevHistoryDirectoriesFromStorage(List<String> devIds) async {
    final result = <String, List<String>>{};
    final client = _client;
    if (client == null) {
      logger.warn(tag, "storage client is null");
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
        logger.warn(tag, "storage client is null");
        return result;
      }
      final list = await client.list(path: devicesInfoDir);
      final deviceIds = list.where((item) => item.isDir).map((item) => item.name).toList();
      for (var devId in deviceIds) {
        if (devId == _selfDevId) {
          continue;
        }
        final dev = await getDeviceInfoFromCloud(devId);
        if (dev == null) {
          logger.warn(tag, "loadDeviceInfo failed, devId = $devId");
          continue;
        }
        result.add(dev);
      }
    } catch (err, stack) {
      logger.error(tag, err, stack);
    }
    return result;
  }

  Future<Map<String, dynamic>?> _readSyncData(String devId, String date, String id, bool loadingMissingData) async {
    final dirPath = getHistoryDatePath(devId, date);
    final path = "$dirPath/$id";
    final bytes = await _client!.readFileBytes(path);
    if (bytes == null) {
      logger.warn(tag, "read file failed, path = $path");
      return null;
    }
    return await _syncData(devId, bytes, loadingMissingData);
  }

  Future<Map<String, dynamic>?> _syncData(String devId, List<int> bytes, bool loadingMissingData) async {
    final deviceService = Get.find<DeviceService>();
    final device = deviceService.getById(devId);
    Map<String, dynamic>? result;
    //on sync
    try {
      final data = m2.deserialize(Uint8List.fromList(bytes)) as Map<dynamic, dynamic>;
      final module = Module.getValue((data["module"]));
      final listeners = getListeners(module);
      final map = data.cast<String, dynamic>();
      result = jsonDecode(jsonEncode(map));
      for (var listener in listeners) {
        // 等待每个监听器完成落库，避免进度先结束但实际数据还没写入本地。
        await listener.onStorageSync(map, device, loadingMissingData);
      }
    } catch (err, stack) {
      logger.error(tag, err, stack);
    }
    return result;
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
      final list = await dbService.opRecordDao.getStorageSyncFiledData(_selfDevId);
      final List<FutureFunction> tasks = [];
      for (var record in list) {
        try {
          // Rebuild the payload before retrying so failed uploads follow the normal send path.
          final syncData = await MissingDataSyncHandler.process(record);
          tasks.add(() async {
            final date = DateTime.parse(record.time).format("yyyy-MM-dd");
            final historyDirPath = getHistoryDatePath(_selfDevId, date);
            if (!await client.createDirectory(historyDirPath)) {
              logger.warn(tag, "retry sync create directory failed! path = $historyDirPath");
              return;
            }
            final id = record.id;
            final path = "$historyDirPath/$id";
            final result = await client.createFile(path, m2.serialize(syncData.result));
            if (!result) {
              return;
            }
            dbService.execSequentially(() => dbService.opRecordDao.updateStorageSyncStatus(id, true));
            final historyId = _historyIdForSync(record);
            if (historyId != null) {
              dbService.execSequentially(() async {
                // Only history records should update local history.sync state after a retry succeeds.
                await dbService.historyDao.setSync(historyId, true);
                final historyController = Get.find<HistoryController>();
                historyController.updateData(
                  (his) => his.id == historyId,
                  (his) => his.sync = true,
                  true,
                );
              });
            }
            // Notify storage peers after retry success so they can load the recovered record.
            final devController = Get.find<DeviceController>();
            final devices = devController.onlineAndPairedList.where((dev) => dev.isUseStorage);
            for (var dev in devices) {
              _wsChannel?.sink.add(WsMsgData(WsMsgType.change, "$date:$id", dev.guid).toString());
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

  void _scheduleWsReconnect() {
    if (!_wsRuntimeState.shouldKeepWsConnected(featureEnabled: appConfig.enableStorageSync && appConfig.enableForward)) {
      return;
    }
    if (_wsReconnectScheduled) {
      return;
    }
    _wsReconnectScheduled = true;
    // Keep retrying while the storage service is still supposed to be active.
    Future.delayed(5.s, () {
      _wsReconnectScheduled = false;
      if (!_wsRuntimeState.shouldKeepWsConnected(featureEnabled: appConfig.enableStorageSync && appConfig.enableForward)) {
        return;
      }
      if (_client == null || _wsChannel != null) {
        return;
      }
      connectWs(true);
    });
  }

  void _handleWsDisconnected({
    required int sessionId,
    required String reason,
    Object? error,
    StackTrace? stack,
  }) {
    final isActiveSession = _wsRuntimeState.isActiveSession(sessionId);
    final ws = isActiveSession ? _wsChannel : null;
    final hadChannel = ws != null;
    if (isActiveSession) {
      _wsRuntimeState.clearActiveSession(sessionId);
      _wsChannel = null;
      _wsPingTimer?.cancel();
      _wsPingTimer = null;
    }
    if (error == null) {
      logger.debug(tag, reason);
    } else {
      logger.error(tag, "$reason: $error", stack);
    }
    if (!isActiveSession) {
      return;
    }
    if (hadChannel) {
      final devIds = _connectedDevIds.toList();
      _connectedDevIds.clear();
      for (var listener in _devAliveListeners) {
        for (var devId in devIds) {
          listener.onDisconnected(devId);
          _registry.removeDevice(devId);
        }
      }
      ws.sink.close();
    }
    _updateForwardDisConnectedStatus();
    _scheduleWsReconnect();
  }

  Future<void> reconnectWs() async {
    if (!_wsRuntimeState.shouldKeepWsConnected(featureEnabled: appConfig.enableStorageSync && appConfig.enableForward)) {
      return;
    }
    await disconnectWs();
    connectWs();
  }

  Future<void> connectWs([bool reconnect = false]) async {
    if (!_wsRuntimeState.shouldKeepWsConnected(featureEnabled: appConfig.enableStorageSync && appConfig.enableForward)) {
      return;
    }
    if (_client == null) {
      return;
    }
    if (_wsChannel != null) {
      logger.warn(tag, "ws already connected");
      return;
    }
    if (reconnect) {
      logger.info(tag, "retry websocket connect");
      if (_wsReconnectScheduled) {
        logger.info(tag, "无网络或连接中，取消重连");
      }
    }
    late final String id;
    if (appConfig.enableWebDAV) {
      id = CryptoUtil.toMD5("${_webDAVConfig!.server}${_webDAVConfig!.username}");
    } else {
      id = CryptoUtil.toMD5("${_s3Config!.endPoint}${_s3Config!.bucketName}${_s3Config!.accessKey}");
    }
    final connectKey = "$id:$_selfDevId";
    var serverHost = appConfig.notificationServer.trimEnd('/');
    logger.info(tag, "开始连接ws");
    final sessionId = _wsRuntimeState.activateNextSession();
    final StorageClient client = _client!;
    late final WebSocketChannel channel;
    try {
      channel = WebSocketChannel.connect(Uri.parse('$serverHost/connect/$connectKey'));
      _wsChannel = channel;
    } catch (err, stack) {
      _handleWsDisconnected(
        sessionId: sessionId,
        reason: "websocket connect failed",
        error: err,
        stack: stack,
      );
      return;
    }
    try {
      await channel.ready;
      if (!_wsRuntimeState.shouldHandleDisconnect(disconnectedSession: sessionId, featureEnabled: appConfig.enableStorageSync && appConfig.enableForward)) {
        return;
      }
      logger.info(tag, "websocket connected");
      _wsReconnectScheduled = false;
      _wsPingTimer = Timer.periodic(Constants.defaultWsPingIntervalTime.s, (_) => _sendWsPing());
      if (!_loadingMissingData) {
        _loadMissingData();
      }
      _updateForwardConnectedStatus();
      final list = await client.list(path: devicesInfoDir);
      final deviceIds = list.where((item) => item.isDir).map((item) => item.name).where((item) => item != _selfDevId).toList();
      for (var devId in deviceIds) {
        _sendOnLineMsg(devId);
      }
    } catch (err, stack) {
      _handleWsDisconnected(
        sessionId: sessionId,
        reason: "websocket ready failed",
        error: err,
        stack: stack,
      );
    }
    channel.stream.listen(
      _onWsMessage,
      onDone: () {
        _handleWsDisconnected(sessionId: sessionId, reason: "ws done");
      },
      onError: (err, stack) {
        _handleWsDisconnected(
          sessionId: sessionId,
          reason: "ws error",
          error: err,
          stack: stack,
        );
      },
    );
  }

  Future<void> disconnectWs() async {
    try {
      final ws = _wsChannel;
      _wsRuntimeState.clearActiveSession();
      _wsChannel = null;
      final devIds = _connectedDevIds.toList();
      _connectedDevIds.clear();
      for (var listener in _devAliveListeners) {
        for (var devId in devIds) {
          listener.onDisconnected(devId);
          //移除已连接的设备
          _registry.removeDevice(devId);
        }
      }
      await ws?.sink.close();
      //停止心跳发送
      _wsPingTimer?.cancel();
      _wsPingTimer = null;
    } catch (err, stack) {
      logger.error(tag, err, stack);
    }
  }

  void connectDevice(String devId) {
    _sendOnLineMsg(devId);
  }

  void disconnectDevice(String devId) {
    _wsChannel?.sink.add(jsonEncode(WsMsgData(WsMsgType.offline, "", devId)));
    for (var listener in _devAliveListeners) {
      listener.onDisconnected(devId);
    }
  }

  void _sendWsPing() {
    _wsChannel?.sink.add(jsonEncode(WsMsgData(WsMsgType.ping, "", "")));
  }

  Future<void> _sendOnLineMsg(String devId) async {
    final ipList = await _getInterfaceIpList();
    final port = appConfig.port;
    _wsChannel?.sink.add(jsonEncode(WsMsgData(WsMsgType.online, jsonEncode({"ipList": ipList, "port": port}), devId)));
  }

  Future<void> _onWsMessage(dynamic json) async {
    try {
      logger.debug(tag, "_onWsMessage $json");
      final msg = WsMsgData.fromJson((jsonDecode(json as String) as Map<dynamic, dynamic>).cast());
      switch (msg.operation) {
        case WsMsgType.online:
          _processOnlineMsg(msg);
          break;
        case WsMsgType.offline:
          _processOfflineMsg(msg);
          break;
        case WsMsgType.change:
          _processChangeMsg(msg);
          break;
        case WsMsgType.syncFile:
          _processSyncFileMsg(msg);
          break;
        case WsMsgType.appInfo:
          _processAppInfoMsg(msg);
          break;
        default:
          logger.error(tag, "unknown ws data type, content = $json");
      }
    } catch (err, stack) {
      logger.error(tag, "_onWsMessage $err, $json", stack);
    }
  }

  ///执行设备连接操作（SocketService设备发现时不能执行）
  Future<bool> _connectDevices() async {
    if (_client == null) {
      logger.warn(tag, "storage client is null");
      return false;
    }
    final sktService = Get.find<SocketService>();
    if (sktService.discovering) {
      //正在设备发现，不能执行
      logger.warn(tag, "SocketService discovering");
      return false;
    }
    final devController = Get.find<DeviceController>();
    //获取已配对且离线的设备
    var offlineAndPairedList = devController.offlineAndPairedList.map((item) => item.guid).toSet();
    //执行连接操作
    for (var devId in offlineAndPairedList) {
      if (_connectedDevIds.contains(devId)) {
        await _connectDevice(devId);
      } else {
        await _sendOnLineMsg(devId);
      }
    }
    return true;
  }

  Future<void> _connectDevice(String devId) async {
    if (_client == null) {
      logger.warn(tag, "storage client is null");
      return;
    }
    final device = await getDeviceInfoFromCloud(devId);
    final version = await getDeviceVersionInfoFromCloud(devId);
    final minVersion = await getDeviceMinVersionInfoFromCloud(devId);
    if (device == null) {
      logger.warn(tag, "device is null, target dev id = $devId");
      return;
    }
    if (version == null) {
      logger.warn(tag, "version is null, target dev id = $devId");
      return;
    }
    if (minVersion == null) {
      logger.warn(tag, "minVersion is null, target dev id = $devId");
      return;
    }
    final isSocket = _registry.getProtocol(device.guid)?.isSocket ?? false;
    if (isSocket) {
      logger.warn(tag, "已通过Socket协议连接: ${device.guid}");
      return;
    }
    final result = await _addOrUpdateDevice(device);
    await _sendOnLineMsg(devId);
    if (!result) {
      logger.warn(tag, "add or update device failed, device = $device");
    }
  }

  // 处理设备连接信息
  // 这里只是记录设备连接状态，按照优先级内网>外网
  // 先等待 socketService 设备发现流程结束，再调用存储服务的设备连接
  Future<void> _processOnlineMsg(WsMsgData msg) async {
    if (msg.targetDevId == _selfDevId) {
      return;
    }
    _connectedDevIds.add(msg.targetDevId);
    var diffNetwork = true;
    if (msg.data.isNotNullAndEmpty) {
      try {
        final json = jsonDecode(msg.data);
        final ipList = (json["ipList"] as List<dynamic>).cast();
        final port = json["port"] as int;
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

    //返回值未false代表未执行连接
    if (!diffNetwork) {
      // Let the socket path win on the same network instead of racing storage connect.
      return;
    }
    final ignored = !await _connectDevices();
    final devController = Get.find<DeviceController>();
    final connected = devController.onlineAndPairedList.where((item) => item.guid == msg.targetDevId).isNotEmpty;
    if (!ignored && !connected) {
      await _connectDevice(msg.targetDevId);
    }
  }

  Future<void> _processOfflineMsg(WsMsgData msg) async {
    final targetDevId = msg.targetDevId;
    _connectedDevIds.remove(targetDevId);
    for (var listener in _devAliveListeners) {
      listener.onDisconnected(targetDevId);
    }
  }

  Future<void> _processChangeMsg(WsMsgData msg) async {
    if (_client == null) {
      logger.warn(tag, "storage client is null");
      return;
    }
    final [date, id] = msg.data.split(":");
    await _readSyncData(msg.targetDevId, date, id, false);
  }

  Future<void> _processSyncFileMsg(WsMsgData msg) async {
    SyncingFile? syncingFile;

    try {
      final startTime = DateTime.now().format();
      final [dateStr, fromDevId, id] = msg.data.split(":");
      final datePath = getHistoryDatePath(fromDevId, dateStr);
      final fileInfoStoragePath = "$datePath/files/$id";
      final bytes = await _client!.readFileBytes(fileInfoStoragePath);
      final json = utf8.decode(bytes!);
      final map = jsonDecode(json);
      final size = map["size"] as int;
      final fileName = map["fileName"] as String;
      final storageFilePath = "$datePath/files/$fileName";
      final localPath = appConfig.fileStorePath + "/$fileName".normalizePath;
      //add syncing file
      final syncingFileService = Get.find<SyncingFileProgressService>();
      Device? dev = await dbService.deviceDao.getById(fromDevId, appConfig.userId);
      if (dev == null) {
        logger.error(tag, "dev:$fromDevId not found");
        return;
      }
      syncingFile = SyncingFile(
        totalSize: size,
        context: Get.context!,
        filePath: localPath,
        fromDev: dev,
        isSender: false,
        startTime: DateTime.now().format(),
      );
      syncingFileService.updateSyncingFile(syncingFile);
      final result = await _client!.downloadFile(
        storageFilePath,
        localPath,
        onProgress: (cnt, total) {
          syncingFile!.updateProgress(cnt);
        },
      );
      if (result) {
        //写入本地记录
        var history = History(
          id: id.toInt(),
          uid: 0,
          devId: fromDevId,
          time: startTime,
          content: localPath,
          type: HistoryContentType.file.value,
          size: size,
          sync: true,
        );
        final historyController = Get.find<HistoryController>();
        historyController.addData(history, null, false).whenComplete(() => syncingFile!.close(true));
        if (!await _client!.deleteFile(fileInfoStoragePath)) {
          logger.warn(tag, "delete storage file info failed! path = $fileInfoStoragePath");
        }
        if (!await _client!.deleteFile(storageFilePath)) {
          logger.warn(tag, "delete storage file failed! path = $storageFilePath");
        }
      } else {
        logger.warn(tag, "_processSyncFileMsg download file failed!. filePath = $storageFilePath, fileInfo = $json");
        syncingFile.close(false);
      }
    } catch (err, stack) {
      syncingFile?.close(false);
      logger.error(tag, "_processSyncFileMsg error: $err", stack);
    }
  }

  Future<void> _processAppInfoMsg(WsMsgData msg) async {
    if (_client == null) {
      logger.warn(tag, "storage client is null");
      return;
    }
    final id = msg.data;
    var dirPath = getAppInfoDirectoryPath(msg.targetDevId);
    var filePath = "$dirPath/$id";
    var bytes = await _client!.readFileBytes(filePath);
    if (bytes == null) {
      logger.warn(tag, "read file failed, path = $filePath");
      return;
    }
    await _syncData(msg.targetDevId, bytes, false);
  }

  Future<bool> _addOrUpdateDevice(Device dev) async {
    final dbDev = await dbService.deviceDao.getById(dev.guid, appConfig.userId);
    final devService = Get.find<DeviceService>();
    final isWebDAV = _client is WebDAVClient;
    final protocol = isWebDAV ? TransportProtocol.webdav : TransportProtocol.s3;
    final address = protocol.name;
    final result = dbDev ?? dev;
    result.isPaired = true;
    result.address = address;
    final success = await devService.addOrUpdate(result);
    if (!success) return false;
    try {
      final devId = result.guid;
      final device = await getDeviceInfoFromCloud(devId);
      final version = await getDeviceVersionInfoFromCloud(devId);
      final minVersion = await getDeviceMinVersionInfoFromCloud(devId);
      if (device == null) {
        logger.warn(tag, "device is null, target dev id = $devId");
        return success;
      }
      if (version == null) {
        logger.warn(tag, "version is null, target dev id = $devId");
        return success;
      }
      if (minVersion == null) {
        logger.warn(tag, "minVersion is null, target dev id = $devId");
        return success;
      }
      for (var listener in _devAliveListeners) {
        listener.onConnected(DevInfo.fromDevice(device), minVersion, version, protocol);
      }
      _registry.addDevice(DevInfo.fromDevice(device), protocol);
    } catch (err, stack) {
      logger.error(tag, err, stack);
    }
    return true;
  }

  //endregion

  //region Update server status
  void _updateForwardConnectingStatus() {
    for (var listener in _forwardStatusListener) {
      listener.onForwardServerConnecting();
    }
  }

  void _updateForwardConnectedStatus() {
    for (var listener in _forwardStatusListener) {
      listener.onForwardServerConnected();
    }
  }

  void _updateForwardDisConnectedStatus() {
    for (var listener in _forwardStatusListener) {
      listener.onForwardServerDisconnected();
    }
  }

  //endregion

  //region Send data

  @override
  Future<void> sendData(
    DevInfo? dev,
    MsgType key,
    Map<String, dynamic> data, [
    bool onlyPaired = true,
  ]) async {
    var id = data["id"];
    if (_client == null) {
      logger.warn(tag, "storage client is null");
      //写入存储服务，更新操作记录
      //仅有少数几个key通过存储服务中转
      if (MsgType.storageServiceKeys.contains(key)) {
        await dbService.opRecordDao.updateStorageSyncStatus(id, false);
      }
      return;
    }
    //仅有少数几个key通过存储服务中转
    if (!MsgType.storageServiceKeys.contains(key)) {
      return;
    }
    final today = DateTime.now().format("yyyy-MM-dd");
    //sync file
    if (key == MsgType.file) {
      await _sendFile(dev!, key, today, data);
    } else {
      //获取module，根据 module 处理
      final module = Module.getValue(data["module"]);
      if (module == Module.appInfo) {
        // Upload appInfo first so notification/history records never arrive before their source data.
        await _uploadAppInfo(AppInfo.fromJson(jsonDecode(data["data"])));
      }
      // 缓存数据，避免批量发送重复写入
      final cacheKey = _buildCacheKey(data);
      final hasData = _cache.contains(cacheKey);
      if (!hasData) {
        _cache.add(cacheKey);
        //缓存 10s
        Future.delayed(10.s, () => _cache.remove(cacheKey));
      }
      await _sendHistory(id, dev, key, today, data, hasData);
    }
  }

  ///从存储服务删除记录
  Future<void> deleteOpRecords(List<OperationRecord> records) async {
    if (_client == null) {
      logger.warn(tag, "storage client is null");
      return;
    }
    for (var record in records) {
      final dir = getHistoryDatePath(_selfDevId, DateTime.parse(record.time).format("yyyy-MM-dd"));
      _client!.deleteFile("$dir/${record.id}");
    }
  }

  //region Send file

  Future<void> _sendFile(
    DevInfo dev,
    MsgType key,
    String today,
    Map<String, dynamic> data,
  ) async {
    //region file info
    final id = appConfig.snowflake.nextId();
    var startTime = DateTime.now().toString();
    final fileName = data["fileName"] as String;
    final isUri = data["isUri"] as bool;
    final filePath = data["filePath"] as String;
    final size = data["size"] as int;
    final datePath = getHistoryDatePath(_selfDevId, today);
    late String storagePath;
    final syncingFileService = Get.find<SyncingFileProgressService>();
    final syncingFile = SyncingFile(
      totalSize: size,
      context: Get.context!,
      filePath: filePath,
      fromDev: appConfig.device,
      isSender: true,
    );
    syncingFileService.updateSyncingFile(syncingFile);
    void onStorageProgressSync(int count, int total) {
      if (syncingFile.state != SyncingFileState.syncing) {
        throw 'Syncing file stop!';
      }
      syncingFile.updateProgress(count);
    }

    final historyController = Get.find<HistoryController>();
    var history = History(
      id: id,
      uid: appConfig.userId,
      devId: appConfig.devInfo.guid,
      time: startTime,
      content: filePath.safeDecodeUri(),
      type: HistoryContentType.file.value,
      size: size,
      sync: true,
    );

    storagePath = "$datePath/files";
    if (_lastDateFilePath != storagePath) {
      if (!await _client!.createDirectory(storagePath)) {
        logger.error(tag, "sync file create directory failed! storageDirPath = $storagePath");
        //file sync progress failed
        syncingFile.setState(SyncingFileState.error);
        return;
      }
      _lastDateFilePath = storagePath;
    }
    final storageFilePath = "$storagePath/$fileName";
    final storageFileInfoPath = "$storagePath/$id";
    //endregion
    if (isUri) {
      //region uri file
      final nullableStream = await uriFileReader.readFileAsBytesStream(filePath);
      if (nullableStream == null) {
        Global.showSnackBarWarn(text: TranslationKey.failedToLoad.tr);
        throw TranslationKey.failedToLoad.tr;
      }
      List<int> fileBytes = [];
      Stream<List<int>> stream = nullableStream.transform(
        StreamTransformer<Uint8List, List<int>>.fromHandlers(
          handleData: (data, sink) {
            sink.add(data);
          },
        ),
      );
      fileBytes = (await stream.toList()).expand((bytes) => bytes).toList();
      // Read the stream before returning so sendData only finishes after upload work does.
      if (size != fileBytes.length) {
        //update sync file progress
        logger.warn(tag, "sync file failed. size ${fileBytes.length} != $size. path = $filePath, storagePath = $storageFilePath");
        syncingFile.setState(SyncingFileState.error);
        return;
      }
      syncingFile.setState(SyncingFileState.syncing);
      final result = await _client!.createFile(storageFilePath, Uint8List.fromList(fileBytes), onProgress: onStorageProgressSync);
      if (!result) {
        //update sync file progress
        logger.warn(tag, "sync file failed. path = $filePath, storagePath = $storageFilePath");
        syncingFile.setState(SyncingFileState.error);
      } else {
        final fileInfoCreated = await _client!.createFile(storageFileInfoPath, utf8.encode(jsonEncode(data)));
        //涓婁紶鏂囦欢淇℃伅
        if (!fileInfoCreated) {
          await _client!.deleteFile(storageFilePath);
          logger.warn(tag, "sync file info failed. path = $storageFileInfoPath. filePath = $filePath");
          return;
        }
        // Only add the local history once for URI files to avoid duplicate records.
        historyController.addData(history, null, false);
        //ws send
        _wsChannel?.sink.add(WsMsgData(WsMsgType.syncFile, "$today:$_selfDevId:$id", dev.guid).toString());
        syncingFile.setState(SyncingFileState.done);
      }
      if (DateTime.now().microsecondsSinceEpoch < 0) {
        stream.listen(
          (bytes) => fileBytes.addAll(bytes),
          onDone: () async {
            //read all
            if (size != fileBytes.length) {
              //update sync file progress
              logger.warn(tag, "sync file failed. size ${fileBytes.length} != $size. path = $filePath, storagePath = $storageFilePath");
              syncingFile.setState(SyncingFileState.error);
              return;
            }
            syncingFile.setState(SyncingFileState.syncing);
            final result = await _client!.createFile(storageFilePath, Uint8List.fromList(fileBytes), onProgress: onStorageProgressSync);
            if (!result) {
              //update sync file progress
              logger.warn(tag, "sync file failed. path = $filePath, storagePath = $storageFilePath");
              syncingFile.setState(SyncingFileState.error);
            } else {
              //上传文件信息
              final result = await _client!.createFile(storageFileInfoPath, utf8.encode(jsonEncode(data)));
              if (!result) {
                await _client!.deleteFile(storageFilePath);
                logger.warn(tag, "sync file info failed. path = $storageFileInfoPath. filePath = $filePath");
                return;
              }
              //本地写入记录
              historyController.addData(history, null, false);
              //ws send
              _wsChannel?.sink.add(WsMsgData(WsMsgType.syncFile, "$today:$_selfDevId:$id", dev.guid).toString());
              syncingFile.setState(SyncingFileState.done);
            }
          },
        );
      }
      //endregion
    } else {
      //region local file
      syncingFile.setState(SyncingFileState.syncing);
      final result = await _client!.uploadFile(storageFilePath, filePath, onProgress: onStorageProgressSync);
      if (!result) {
        //update sync file progress
        logger.warn(tag, "sync file failed. path = $filePath, storagePath = $storageFilePath");
        syncingFile.setState(SyncingFileState.error);
      } else {
        //上传文件信息
        final result = await _client!.createFile(storageFileInfoPath, utf8.encode(jsonEncode(data)));
        if (!result) {
          await _client!.deleteFile(storageFilePath);
          logger.warn(tag, "sync file info failed. path = $storageFileInfoPath. filePath = $filePath");
          return;
        }
        //本地写入记录
        historyController.addData(history, null, false);
        //ws send
        _wsChannel?.sink.add(WsMsgData(WsMsgType.syncFile, "$today:$_selfDevId:$id", dev.guid).toString());
        syncingFile.setState(SyncingFileState.done);
      }
      //endregion
    }
    return;
  }

  //endregion

  //region Send history
  Future<void> _sendHistory(
    int id,
    DevInfo? dev,
    MsgType key,
    String today,
    Map<String, dynamic> data,
    bool hasData,
  ) async {
    if (!hasData) {
      //写入存储服务
      if (today != _lastDate) {
        _lastDate = today;
        final path = getHistoryDatePath(_selfDevId, today);
        final result = await _client!.createDirectory(path);
        if (!result) {
          // Mark the record unsynced here so the retry query can pick it up again later.
          await dbService.opRecordDao.updateStorageSyncStatus(id, false);
          logger.warn(tag, "create history date directory failed! path = $path");
          return;
        }
      }
      var historyDirPath = getHistoryDatePath(_selfDevId, today);
      final path = "$historyDirPath/$id";
      final result = await _client!.createFile(path, m2.serialize(data));
      //写入存储服务，更新操作记录
      dbService.opRecordDao.updateStorageSyncStatus(id, result);
      if (!result) {
        logger.warn(tag, "StorageService write data failed! key=${key.name}, data = ${jsonEncode(data)}");
        return;
      }
    }
    // notify
    if (dev != null) {
      _wsChannel?.sink.add(WsMsgData(WsMsgType.change, "$today:$id", dev.guid).toString());
    }
  }

  //endregion

  //region Path getter

  String getDeviceInfoPath(String devId) {
    return "$devicesInfoDir/$devId/deviceInfo.json";
  }

  String getDeviceVersionPath(String devId) {
    return "$devicesInfoDir/$devId/version.json";
  }

  String getDeviceMinVersionPath(String devId) {
    return "$devicesInfoDir/$devId/minVersion.json";
  }

  String getHistoryDatePath(String devId, String date) {
    return "$historyDir/$devId/$date";
  }

  String getHistoryDirectoryPath(String devId) {
    return "$historyDir/$devId";
  }

  String getAppInfoDirectoryPath(String devId) {
    return "$appInfoDir/$devId";
  }

  String _buildCacheKey(Map<String, dynamic> data) {
    return jsonEncode(data);
  }

  //endregion

  //region BaseInfo getter

  Future<Device?> getDeviceInfoFromCloud(String devId) async {
    final bytes = await _client?.readFileBytes(getDeviceInfoPath(devId));
    if (bytes == null) return null;
    return Device.fromJson((jsonDecode(utf8.decode(bytes)) as Map<dynamic, dynamic>).cast());
  }

  Future<AppVersion?> getDeviceVersionInfoFromCloud(String devId) async {
    final bytes = await _client?.readFileBytes(getDeviceVersionPath(devId));
    if (bytes == null) return null;
    return AppVersion.fromJson((jsonDecode(utf8.decode(bytes)) as Map<dynamic, dynamic>).cast());
  }

  Future<AppVersion?> getDeviceMinVersionInfoFromCloud(String devId) async {
    final bytes = await _client?.readFileBytes(getDeviceMinVersionPath(devId));
    if (bytes == null) return null;
    return AppVersion.fromJson((jsonDecode(utf8.decode(bytes)) as Map<dynamic, dynamic>).cast());
  }

  @override
  void onDiscoverFinished() {
    _connectDevices();
  }

  @override
  void onDiscoverStart() {
    //ignore
  }

  //endregion

  ///获取所有网卡 ip
  Future<List<String>> _getInterfaceIpList() async {
    final interfaces = await NetworkInterfaceFilterUtil.listInterfaces();
    var expendAddress = interfaces.map((networkInterface) => networkInterface.addresses).expand((ip) => ip);
    return expendAddress.where((ip) => ip.type == InternetAddressType.IPv4).map((address) => address.address).toList();
  }

  /// 只有历史记录重传成功后，才需要回写 history 表的 sync 状态。
  static int? _historyIdForSync(OperationRecord record) {
    if (record.module != Module.history) {
      return null;
    }
    return int.tryParse(record.data);
  }
}
