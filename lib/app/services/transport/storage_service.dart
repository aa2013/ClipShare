import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:clipshare/app/data/enums/history_content_type.dart';
import 'package:clipshare/app/data/enums/forward_server_status.dart';
import 'package:clipshare/app/data/enums/module.dart';
import 'package:clipshare/app/data/enums/msg_type.dart';
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
import 'package:clipshare/app/data/repository/entity/tables/operation_sync.dart';
import 'package:clipshare/app/data/repository/entity/tables/pending_storage_ack.dart';
import 'package:clipshare/app/exceptions/different_storage_client_type_exception.dart';
import 'package:clipshare/app/handlers/storage/storage_client.dart';
import 'package:clipshare/app/handlers/storage/web_dav_client.dart';
import 'package:clipshare/app/handlers/sync/abstract_data_sender.dart';
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
import 'package:clipshare/app/services/transport/storage_ws_service.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/crypto.dart';
import 'package:clipshare/app/utils/extensions/device_extension.dart';
import 'package:clipshare/app/utils/extensions/number_extension.dart';
import 'package:clipshare/app/utils/extensions/storage_config_extension.dart';
import 'package:clipshare/app/utils/extensions/string_extension.dart';
import 'package:clipshare/app/utils/extensions/time_extension.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:clipshare/app/utils/network_util.dart';
import 'package:clipshare/app/utils/parallerl_task.dart';
import 'package:get/get.dart';
import "package:msgpack_dart/msgpack_dart.dart" as m2;
import 'package:uri_file_reader/uri_file_reader.dart';

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
  late final StorageWsService _wsService;

  bool get running => _wsService.running;

  //region dev registry
  final DeviceConnectionRegistry _registry;

  List<DevAliveListener> get _devAliveListeners => _registry.devAliveListeners;

  List<ForwardStatusListener> get _forwardStatusListener => _registry.forwardStatusListener;

  //endregion

  StorageClient? _client;

  StorageService(this._registry) {
    _wsService = StorageWsService(
      connectUriBuilder: _buildWsUri,
      shouldKeepConnected: _shouldKeepWsConnected,
      pingInterval: const Duration(seconds: Constants.defaultWsPingIntervalTime),
      onConnected: _onWsConnected,
      onDisconnected: _onWsDisconnected,
      onMessage: _dispatchWsMessage,
      onStatusChanged: _onWsStatusChanged,
    );
  }

  WebDAVConfig? get _webDAVConfig => appConfig.webDAVConfig;

  S3Config? get _s3Config => appConfig.s3Config;

  Uri _buildWsUri() {
    late final String storageId;
    if (appConfig.enableWebDAV) {
      storageId = CryptoUtil.toMD5("${_webDAVConfig!.server}${_webDAVConfig!.username}");
    } else {
      storageId = CryptoUtil.toMD5("${_s3Config!.endPoint}${_s3Config!.bucketName}${_s3Config!.accessKey}");
    }
    final connectKey = "$storageId:$_selfDevId";
    final serverHost = appConfig.notificationServer.trimEnd('/');
    return Uri.parse('$serverHost/connect/$connectKey');
  }

  bool _shouldKeepWsConnected() {
    return appConfig.enableStorageSync && appConfig.enableForward && _client != null;
  }

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
    // WebDAV 在部分服务端上不会自动补父目录，这里统一让写文件顺带补齐路径。
    await client.createFile(
      getDeviceInfoPath(_selfDevId),
      utf8.encode(jsonEncode(device)),
      createDir: true,
    );
    await client.createFile(
      getDeviceVersionPath(_selfDevId),
      utf8.encode(jsonEncode(appConfig.version)),
      createDir: true,
    );
    await client.createFile(
      getDeviceMinVersionPath(_selfDevId),
      utf8.encode(jsonEncode(appConfig.minVersion)),
      createDir: true,
    );
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
    final client = _client;
    if (client == null) {
      logger.warn(tag, "_uploadAppInfo storage client is null");
      return false;
    }
    if (!await client.createDirectory(dirPath)) {
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
    final success = await client.createFile(path, m2.serialize(result.result), createDir: true);
    if (!success) {
      logger.warn(tag, "upload appInfo($id) failed");
      return false;
    }
    //ws send
    final devController = Get.find<DeviceController>();
    for (var dev in devController.onlineAndPairedList) {
      _wsService.send(WsMsgData(WsMsgType.appInfo, id.toString(), dev.guid));
    }
    return true;
  }

  /// 检查并下载缺失的其他设备的app信息
  Future<void> _checkAndDownloadMissingAppInfo(String devId) async {
    final client = _client;
    if (client == null) {
      logger.warn(tag, "_checkAndDownloadMissingAppInfo storage client is null");
      return;
    }
    final dirPath = getAppInfoDirectoryPath(devId);
    final sourceService = Get.find<ClipboardSourceService>();
    final list = await client.list(path: dirPath);
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
    if (!appConfig.enableStorageSync) {
      return;
    }
    if (!appConfig.enableForward) {
      return;
    }
    connRegService.addDiscoverListener(this);
    if (appConfig.enableS3 && _s3Config != null) {
      _client = _s3Config!.toClient();
    } else if (appConfig.enableWebDAV && _webDAVConfig != null) {
      _client = _webDAVConfig!.toClient();
    } else {
      throw 'storage service config is null';
    }
    _updateForwardStatus(ForwardServerStatus.initializing);
    if (!await _createBaseDirectories()) {
      logger.warn(tag, "create base directories failed!");
      _client = null;
      _updateForwardStatus(ForwardServerStatus.disconnected);
      return;
    }
    try {
      await _updateBaseInfo();
      await _checkAndUploadLocalAppInfo();
      uploadSyncFailedData();
      _loadMissingData();
      await _wsService.connect();
    } catch (err, stack) {
      logger.error(tag, err, stack);
      await _wsService.disconnect();
      _updateForwardStatus(ForwardServerStatus.disconnected);
    }
  }

  Future<void> stop() async {
    _client = null;
    _lastDate = '';
    _lastDateFilePath = '';
    connRegService.removeDiscoverListener(this);
    await _wsService.disconnect();
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
    final devHistoryDirMap = await _loadDevHistoryDirectoriesFromStorage(devIds);

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
      totalSyncCnt += devDateSyncMap.values.fold(0, (prev, ids) => prev + ids.length);
    }

    final List<FutureFunction> tasks = [];
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
    final latestRecord = await dbService.opRecordDao.getLatestStorageSyncSuccessByDevId(devId);
    final latestDate = DateTime.parse(latestRecord?.time ?? "1970-01-01");
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
        logger.error(tag, "loadMissingData error: $err", stack);
      }
    }

    return devDateSyncMap;
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
    final client = _client;
    if (client == null) {
      logger.warn(tag, "_readSyncData storage client is null");
      return null;
    }
    final dirPath = getHistoryDatePath(devId, date);
    final path = "$dirPath/$id";
    final bytes = await client.readFileBytes(path);
    if (bytes == null) {
      logger.warn(tag, "read file failed, path = $path");
      return null;
    }
    final syncData = await _syncData(devId, bytes, loadingMissingData);
    if (syncData != null) {
      await _sendOrQueueStorageAck(syncData["id"], devId);
    }
    return syncData;
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
      if (listeners.isEmpty) {
        logger.warn(tag, "storage sync listener not found. module=${module.moduleName}");
        return null;
      }
      final map = data.cast<String, dynamic>();
      for (var listener in listeners) {
        // 等待每个监听器完成落库，避免进度先结束但实际数据还没写入本地。
        await listener.onStorageSync(map, device, loadingMissingData);
      }
      result = jsonDecode(jsonEncode(map));
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
            final result = await client.createFile(path, m2.serialize(syncData.result), createDir: true);
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
              _wsService.send(WsMsgData(WsMsgType.change, "$date:$id", dev.guid));
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
    await _wsService.disconnect();
  }

  void connectDevice(String devId) {
    logger.info(tag, "send online presence. targetDevId=$devId, source=connectDevice");
    unawaited(_sendOnLineMsg(devId, source: 'connectDevice'));
  }

  void disconnectDevice(String devId) {
    logger.info(tag, "send offline presence. targetDevId=$devId, source=disconnectDevice");
    _wsService.send(WsMsgData(WsMsgType.offline, "", devId));
    _handleDeviceDisconnected(devId, source: 'disconnectDevice');
  }

  /// 统一记录 online presence 的发送来源，便于排查重连和手动连接场景。
  Future<void> _sendOnLineMsg(String devId, {required String source}) async {
    try {
      final ipList = await _getInterfaceIpList();
      final port = appConfig.port;
      _wsService.send(
        WsMsgData(
          WsMsgType.online,
          jsonEncode({"ipList": ipList, "port": port}),
          devId,
        ),
      );
      logger.info(
        tag,
        "send online presence. targetDevId=$devId, source=$source, ipCount=${ipList.length}, port=$port",
      );
    } catch (err, stack) {
      logger.error(
        tag,
        "build online presence failed. targetDevId=$devId, source=$source, error=$err",
        stack,
      );
    }
  }

  Future<void> _dispatchWsMessage(WsMsgData msg) async {
    logger.debug(tag, "_onWsMessage ${msg.toJson()}");
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
        logger.error(tag, "unknown ws data type, content = ${msg.toJson()}");
    }
  }

  Future<void> _onWsConnected() async {
    if (!_loadingMissingData) {
      unawaited(_loadMissingData());
    }
    final client = _client;
    if (client == null) {
      logger.warn(tag, "storage client is null");
      return;
    }
    final list = await client.list(path: devicesInfoDir);
    final deviceIds = list.where((item) => item.isDir).map((item) => item.name).where((item) => item != _selfDevId).toList();
    logger.debug(tag, "broadcast online presence after ws connected. targetCount=${deviceIds.length}");
    for (var devId in deviceIds) {
      await _sendOnLineMsg(devId, source: 'wsConnectedBroadcast');
    }
  }

  Future<void> _onWsDisconnected() async {
    final devIds = _connectedDevIds.toList();
    logger.debug(tag, "handle ws disconnected cleanup. targetCount=${devIds.length}");
    for (var devId in devIds) {
      _handleDeviceDisconnected(devId, source: 'wsDisconnected');
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
        logger.debug(tag, "reconnect device after online presence. targetDevId=$devId");
        await _connectDevice(devId);
      } else {
        logger.debug(tag, "send online presence for offline paired device. targetDevId=$devId");
        await _sendOnLineMsg(devId, source: 'connectDevices');
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
    logger.debug(tag, "send online presence after connect device. targetDevId=$devId");
    await _sendOnLineMsg(devId, source: 'connectDeviceInternal');
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
    unawaited(_retryPendingAcksForDevice(msg.targetDevId));
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
    if (!_loadingMissingData) {
      // 对端重连后主动补拉其离线期间写入的历史，避免只依赖 change 事件导致漏同步。
      unawaited(_reloadMissingDataForDevice(msg.targetDevId));
    }
  }

  /// 对单个重连设备执行一次缺失数据补拉，复用全量补拉的筛选与读取逻辑。
  Future<void> _reloadMissingDataForDevice(String devId) async {
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

      void checkClientRuntimeType() {
        final currentType = _client?.runtimeType;
        if (clientType != currentType) {
          throw DifferentStorageClientTypeException('current storage client($currentType) is not a $clientType');
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
    logger.debug(tag, "receive offline presence. targetDevId=$targetDevId");
    _handleDeviceDisconnected(targetDevId, source: 'offlineMessage');
  }

  Future<void> _processChangeMsg(WsMsgData msg) async {
    if (_client == null) {
      logger.warn(tag, "storage client is null");
      return;
    }
    final [date, id] = msg.data.split(":");
    await _readSyncData(msg.targetDevId, date, id, false);
  }

  Future<void> _processAckMsg(WsMsgData msg) async {
    try {
      final data = (jsonDecode(msg.data) as Map<dynamic, dynamic>).cast<String, dynamic>();
      final opId = data["opId"] as int;
      final devId = data["devId"] as String;
      await dbService.opSyncDao.add(
        OperationSync(opId: opId, devId: devId, uid: appConfig.userId),
      );
    } catch (err, stack) {
      logger.error(tag, "process storage ack failed. msg=${msg.toJson()}, err=$err", stack);
    }
  }

  Future<void> _sendOrQueueStorageAck(dynamic opId, String targetDevId) async {
    if (opId is! int) {
      logger.warn(tag, "storage ack opId invalid. opId=$opId, targetDevId=$targetDevId");
      return;
    }
    if (!_connectedDevIds.contains(targetDevId)) {
      await dbService.pendingStorageAckDao.add(
        PendingStorageAck(opId: opId, targetDevId: targetDevId),
      );
      return;
    }
    final sent = _sendStorageAck(opId, targetDevId);
    if (sent) {
      return;
    }
    await dbService.pendingStorageAckDao.add(
      PendingStorageAck(opId: opId, targetDevId: targetDevId),
    );
  }

  bool _sendStorageAck(int opId, String targetDevId) {
    return _wsService.send(
      WsMsgData(
        WsMsgType.ack,
        jsonEncode({"opId": opId, "devId": _selfDevId}),
        targetDevId,
      ),
    );
  }

  Future<void> _retryPendingAcksForDevice(String targetDevId) async {
    final list = await dbService.pendingStorageAckDao.getByTargetDevId(targetDevId);
    for (final ack in list) {
      if (_sendStorageAck(ack.opId, targetDevId)) {
        await dbService.pendingStorageAckDao.removeByKey(ack.opId, targetDevId);
      }
    }
  }

  Future<void> _processSyncFileMsg(WsMsgData msg) async {
    SyncingFile? syncingFile;
    final client = _client;
    if (client == null) {
      logger.warn(tag, "_processSyncFileMsg storage client is null");
      return;
    }
    try {
      final startTime = DateTime.now().format();
      final [dateStr, fromDevId, id] = msg.data.split(":");
      final datePath = getHistoryDatePath(fromDevId, dateStr);
      final fileInfoStoragePath = "$datePath/files/$id";
      final bytes = await client.readFileBytes(fileInfoStoragePath);
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
      final result = await client.downloadFile(
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
        if (!await client.deleteFile(fileInfoStoragePath)) {
          logger.warn(tag, "delete storage file info failed! path = $fileInfoStoragePath");
        }
        if (!await client.deleteFile(storageFilePath)) {
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
    final client = _client;
    if (client == null) {
      logger.warn(tag, "_processAppInfoMsg storage client is null");
      return;
    }
    final id = msg.data;
    var dirPath = getAppInfoDirectoryPath(msg.targetDevId);
    var filePath = "$dirPath/$id";
    var bytes = await client.readFileBytes(filePath);
    if (bytes == null) {
      logger.warn(tag, "read file failed, path = $filePath");
      return;
    }
    final syncData = await _syncData(msg.targetDevId, bytes, false);
    if (syncData != null) {
      // appInfo 的 websocket 通知只带 appInfo.id，ACK 需要使用文件内容里的操作记录 id。
      await _sendOrQueueStorageAck(syncData["id"], msg.targetDevId);
    }
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
  /// 统一向所有观察方广播状态，减少内部样板和状态命名分叉。
  void _updateForwardStatus(ForwardServerStatus status) {
    for (var listener in _forwardStatusListener) {
      listener.onForwardServerStatusChanged(status);
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
    final client = _client;
    if (client == null) {
      logger.warn(tag, "deleteOpRecords storage client is null");
      return;
    }
    for (var record in records) {
      final dir = getHistoryDatePath(_selfDevId, DateTime.parse(record.time).format("yyyy-MM-dd"));
      client.deleteFile("$dir/${record.id}");
    }
  }

  //region Send file

  Future<void> _sendFile(
    DevInfo dev,
    MsgType key,
    String today,
    Map<String, dynamic> data,
  ) async {
    final client = _client;
    if (client == null) {
      logger.warn(tag, "_sendFile storage client is null");
      return;
    }
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
      if (!await client.createDirectory(storagePath)) {
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
      final result = await client.createFile(
        storageFilePath,
        Uint8List.fromList(fileBytes),
        onProgress: onStorageProgressSync,
        createDir: true,
      );
      if (!result) {
        //update sync file progress
        logger.warn(tag, "sync file failed. path = $filePath, storagePath = $storageFilePath");
        syncingFile.setState(SyncingFileState.error);
      } else {
        final fileInfoCreated = await client.createFile(
          storageFileInfoPath,
          utf8.encode(jsonEncode(data)),
          createDir: true,
        );
        //涓婁紶鏂囦欢淇℃伅
        if (!fileInfoCreated) {
          await client.deleteFile(storageFilePath);
          logger.warn(tag, "sync file info failed. path = $storageFileInfoPath. filePath = $filePath");
          return;
        }
        // Only add the local history once for URI files to avoid duplicate records.
        historyController.addData(history, null, false);
        //ws send
        _wsService.send(WsMsgData(WsMsgType.syncFile, "$today:$_selfDevId:$id", dev.guid));
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
            final result = await client.createFile(
              storageFilePath,
              Uint8List.fromList(fileBytes),
              onProgress: onStorageProgressSync,
              createDir: true,
            );
            if (!result) {
              //update sync file progress
              logger.warn(tag, "sync file failed. path = $filePath, storagePath = $storageFilePath");
              syncingFile.setState(SyncingFileState.error);
            } else {
              //上传文件信息
              final result = await client.createFile(
                storageFileInfoPath,
                utf8.encode(jsonEncode(data)),
                createDir: true,
              );
              if (!result) {
                await client.deleteFile(storageFilePath);
                logger.warn(tag, "sync file info failed. path = $storageFileInfoPath. filePath = $filePath");
                return;
              }
              //本地写入记录
              historyController.addData(history, null, false);
              //ws send
              _wsService.send(WsMsgData(WsMsgType.syncFile, "$today:$_selfDevId:$id", dev.guid));
              syncingFile.setState(SyncingFileState.done);
            }
          },
        );
      }
      //endregion
    } else {
      //region local file
      syncingFile.setState(SyncingFileState.syncing);
      final result = await client.uploadFile(storageFilePath, filePath, onProgress: onStorageProgressSync);
      if (!result) {
        //update sync file progress
        logger.warn(tag, "sync file failed. path = $filePath, storagePath = $storageFilePath");
        syncingFile.setState(SyncingFileState.error);
      } else {
        //上传文件信息
        final result = await client.createFile(
          storageFileInfoPath,
          utf8.encode(jsonEncode(data)),
          createDir: true,
        );
        if (!result) {
          await client.deleteFile(storageFilePath);
          logger.warn(tag, "sync file info failed. path = $storageFileInfoPath. filePath = $filePath");
          return;
        }
        //本地写入记录
        historyController.addData(history, null, false);
        //ws send
        _wsService.send(WsMsgData(WsMsgType.syncFile, "$today:$_selfDevId:$id", dev.guid));
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
    final client = _client;
    if (client == null) {
      logger.warn(tag, "_sendHistory storage client is null");
      return;
    }
    if (!hasData) {
      //写入存储服务
      if (today != _lastDate) {
        _lastDate = today;
        final path = getHistoryDatePath(_selfDevId, today);
        final result = await client.createDirectory(path);
        if (!result) {
          // Mark the record unsynced here so the retry query can pick it up again later.
          await dbService.opRecordDao.updateStorageSyncStatus(id, false);
          logger.warn(tag, "create history date directory failed! path = $path");
          return;
        }
      }
      var historyDirPath = getHistoryDatePath(_selfDevId, today);
      final path = "$historyDirPath/$id";
      final result = await client.createFile(path, m2.serialize(data), createDir: true);
      //写入存储服务，更新操作记录
      dbService.opRecordDao.updateStorageSyncStatus(id, result);
      if (!result) {
        logger.warn(tag, "StorageService write data failed! key=${key.name}, data = ${jsonEncode(data)}");
        return;
      }
    }
    // notify
    if (dev != null) {
      _wsService.send(WsMsgData(WsMsgType.change, "$today:$id", dev.guid));
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
    final interfaces = await NetworkUtil.listInterfaces();
    var expendAddress = interfaces.map((networkInterface) => networkInterface.addresses).expand((ip) => ip);
    return expendAddress.where((ip) => ip.type == InternetAddressType.IPv4).map((address) => address.address).toList();
  }

  /// 统一处理设备离线时的本地状态收口，避免注册表和监听器状态漂移。
  void _handleDeviceDisconnected(String devId, {required String source}) {
    final removedConnected = _connectedDevIds.remove(devId);
    final existedInRegistry = _registry.hasDevice(devId);
    if (existedInRegistry) {
      _registry.removeDevice(devId);
    }
    logger.debug(
      tag,
      "cleanup disconnected device. targetDevId=$devId, source=$source, removedConnected=$removedConnected, removedRegistry=$existedInRegistry",
    );
    for (var listener in _devAliveListeners) {
      listener.onDisconnected(devId);
    }
  }

  /// 只有历史记录重传成功后，才需要回写 history 表的 sync 状态。
  static int? _historyIdForSync(OperationRecord record) {
    if (record.module != Module.history) {
      return null;
    }
    return int.tryParse(record.data);
  }
}
