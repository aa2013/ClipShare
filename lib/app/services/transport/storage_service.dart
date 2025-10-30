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
import 'package:clipshare/app/data/models/missing_data_sync_progress.dart';
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
import 'package:clipshare/app/modules/home_module/home_controller.dart';
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
import 'package:clipshare/app/utils/task_runner.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import "package:msgpack_dart/msgpack_dart.dart" as m2;
import 'package:uri_file_reader/uri_file_reader.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

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
  static const _baseDirs = [devicesInfoDir, historyDir, appInfoDir];

  String get _selfDevId => appConfig.device.guid;
  var _lastDate = '';
  var _lastDateFilePath = '';
  final _cache = <dynamic>{};
  var _loadingMissingData = false;
  var _uploadingSyncFailedData = false;

  bool get running => _client != null;

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

  WebDavConfig? get _webDavConfig => appConfig.webDavConfig;

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
      result = result && await _client!.createDirectory(dirPath);
    }
    return result;
  }

  Future<void> _updateBaseInfo() async {
    if (_client == null) {
      Log.warn(tag, "storage client is null");
      return;
    }
    final device = appConfig.device.copyWith(customName: appConfig.localName);
    await _client!.createFile(getDeviceInfoPath(_selfDevId), utf8.encode(jsonEncode(device)));
    await _client!.createFile(getDeviceVersionPath(_selfDevId), utf8.encode(jsonEncode(appConfig.version)));
    await _client!.createFile(getDeviceMinVersionPath(_selfDevId), utf8.encode(jsonEncode(appConfig.minVersion)));
  }

  /// 检查并上传缺失的本机app信息
  Future<void> _checkAndUploadLocalAppInfo() async {
    if (_client == null) {
      Log.warn(tag, "storage client is null");
      return;
    }
    final dirPath = getAppInfoDirectoryPath(_selfDevId);
    var result = await _client!.createDirectory(dirPath);
    if (!result) {
      Log.debug(tag, "checkAndUploadLocalAppInfo failed");
      return;
    }
    final sourceService = Get.find<ClipboardSourceService>();
    var list = sourceService.appInfos.where((item) => item.devId == _selfDevId).toList();
    final existsIds = (await _client!.list(path: dirPath)).map((item) => item.name).toSet();
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
      Log.debug(tag, "_uploadAppInfo createDirectory $dirPath failed.");
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
      Log.warn(tag, "upload appInfo($id) failed");
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
      Log.warn(tag, "storage client is null");
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
        Log.error(tag, "_checkAndDownloadMissingAppInfo error: $err", stack);
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
      if (_s3Config!.type == ObjStorageType.aliyunOss) {
        _client = AliyunOssClient(_s3Config!);
      } else {
        _client = S3Client(_s3Config!);
      }
    } else if (appConfig.enableWebdav && _webDavConfig != null) {
      _client = WebDavClient(_webDavConfig!);
    } else {
      throw 'storage service config is null';
    }
    if (!await _createBaseDirectories()) {
      Log.warn(tag, "create base directories failed!");
      _client = null;
      return;
    }
    await _updateBaseInfo();
    await _checkAndUploadLocalAppInfo();
    uploadSyncFailedData();
    _loadMissingData();
    connectWs();
  }

  Future<void> stop() async {
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
    if (_client == null) {
      Log.warn(tag, "storage client is null");
      return;
    }
    if (!appConfig.autoSyncMissingData) {
      Log.warn(tag, "autoSyncMissingData is false");
      return;
    }
    if (_loadingMissingData) {
      return;
    }
    _loadingMissingData = true;
    final clientType = _client.runtimeType;

    ///检查客户端类型是否和初始的相同，如果不同则表示用户切换了中转类型，需要终止该方法
    void checkClientRuntimeType() {
      if (clientType != _client.runtimeType) {
        _loadingMissingData = false;
        throw DifferentStorageClientTypeException('current storage client(${_client.runtimeType}) is not a $clientType');
      }
    }

    final devices = await _loadDeviceInfosFromStorage();
    if (devices.isEmpty) {
      Log.warn(tag, "storage devices is empty");
      return;
    }

    //add or update devices
    for (var dev in devices) {
      checkClientRuntimeType();
      if (dev.guid == _selfDevId) {
        continue;
      }
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
      syncMap[devId] = {};
      var historyDates = devHistoryDirMap[devId]!;
      for (var date in historyDates) {
        // filter date
        if (DateTime.parse(date).isBefore(latestDate.date)) {
          continue;
        }
        syncMap[devId]![date] = [];
        try {
          final path = getHistoryDatePath(devId, date);
          final items = await _client!.list(path: path);
          //filter id
          final ids = items.where((item) => !item.isDir).map((item) => item.name).where((id) => int.parse(id) > latestId).toList()..sort((a, b) => int.parse(b) - int.parse(a));
          totalSyncCnt += ids.length;
          for (var id in ids) {
            checkClientRuntimeType();
            syncMap[devId]![date]!.add(id);
          }
        } catch (err, stack) {
          Log.error(tag, "loadMissingData error: $err", stack);
        }
      }
    }
    //endregion

    final List<FutureFunction> tasks = [];
    //region load missing data file
    for (var devId in syncMap.keys) {
      for (var date in syncMap[devId]!.keys) {
        for (var id in syncMap[devId]![date]!) {
          tasks.add(() async {
            Map<String, dynamic>? syncData;
            try {
              checkClientRuntimeType();
              syncData = await _readSyncData(devId, date, id, true);
            } catch (err, stack) {
              if (err is DifferentStorageClientTypeException) {
                return;
              }
              Log.error(tag, "load missing data file from storage failed! devId = $devId, date = $date, id = $id", stack);
            } finally {
              historySyncProgressService.addProgress(devId, syncData, ++syncedCnt, totalSyncCnt);
            }
          });
        }
      }
    }
    //endregion

    TaskRunner(
      concurrency: 10,
      initialTasks: tasks,
      onFinish: () {
        _loadingMissingData = false;
      },
    );
  }

  Future<Map<String, List<String>>> _loadDevHistoryDirectoriesFromStorage(List<String> devIds) async {
    final result = <String, List<String>>{};
    if (_client == null) {
      Log.warn(tag, "storage client is null");
      return result;
    }
    for (var devId in devIds) {
      try {
        final list = await _client!.list(path: getHistoryDirectoryPath(devId));
        final directoryNames = list.where((item) => item.isDir).map((item) => item.name).toList();
        result[devId] = directoryNames;
      } catch (err, stack) {
        Log.error(tag, err, stack);
      }
    }
    return result;
  }

  Future<List<Device>> _loadDeviceInfosFromStorage() async {
    final result = List<Device>.empty(growable: true);
    try {
      if (_client == null) {
        Log.warn(tag, "storage client is null");
        return result;
      }
      final list = await _client!.list(path: devicesInfoDir);
      final deviceIds = list.where((item) => item.isDir).map((item) => item.name).toList();
      for (var devId in deviceIds) {
        final dev = await getDeviceInfoFromCloud(devId);
        if (dev == null) {
          Log.warn(tag, "loadDeviceInfo failed, devId = $devId");
          continue;
        }
        result.add(dev);
      }
    } catch (err, stack) {
      Log.error(tag, err, stack);
    }
    return result;
  }

  Future<Map<String, dynamic>?> _readSyncData(String devId, String date, String id, bool loadingMissingData) async {
    final dirPath = getHistoryDatePath(devId, date);
    final path = "$dirPath/$id";
    final bytes = await _client!.readFileBytes(path);
    if (bytes == null) {
      Log.warn(tag, "read file failed, path = $path");
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
        listener.onStorageSync(map, device, loadingMissingData);
      }
    } catch (err, stack) {
      Log.error(tag, err, stack);
    }
    return result;
  }

  //endregion

  //region Upload sync failed data
  Future<void> uploadSyncFailedData() async {
    if (_uploadingSyncFailedData) {
      return;
    }
    if (_client == null) {
      return;
    }
    _uploadingSyncFailedData = true;
    final list = await dbService.opRecordDao.getStorageSyncFiledData(_selfDevId);
    final List<FutureFunction> tasks = [];
    for (var record in list) {
      try {
        //process record
        final syncData = await MissingDataSyncHandler.process(record);
        tasks.add(() async {
          final date = DateTime.parse(record.time).format("yyyy-MM-dd");
          final historyDirPath = getHistoryDatePath(_selfDevId, date);
          final id = record.id;
          final path = "$historyDirPath/$id";
          final result = await _client!.createFile(path, m2.serialize(syncData.result));
          if (result) {
            dbService.execSequentially(() => dbService.opRecordDao.updateStorageSyncStatus(id, true));
            dbService.execSequentially(() async {
              final id = int.parse(record.data);
              await dbService.historyDao.setSync(id, true);
              final historyController = Get.find<HistoryController>();
              historyController.updateData((his) => his.id == id, (his) => his.sync = true, true);
            });
            //notify+
            //拿到所有在线且配对的通过存储中转的设备
            final devController = Get.find<DeviceController>();
            final devices = devController.onlineAndPairedList.where((dev) => dev.isUseStorage);
            for (var dev in devices) {
              _wsChannel?.sink.add(WsMsgData(WsMsgType.change, "$date:$id", dev.guid));
            }
          }
        });
      } catch (err, stack) {
        Log.error(tag, err, stack);
      }
    }
    TaskRunner(
      concurrency: 10,
      initialTasks: tasks,
      onFinish: () {
        _uploadingSyncFailedData = false;
      },
    );
  }

  //endregion

  //region Websocket message process

  Future<void> reconnectWs() async {
    await disconnectWs();
    connectWs();
  }

  void connectWs() {
    if (!appConfig.enableStorageSync) {
      return;
    }
    if (!appConfig.enableForward) {
      return;
    }
    if (_wsChannel != null) {
      Log.warn(tag, "ws already connected");
      return;
    }
    late final String id;
    if (appConfig.enableWebdav) {
      id = CryptoUtil.toMD5("${_webDavConfig!.server}${_webDavConfig!.username}");
    } else {
      id = CryptoUtil.toMD5("${_s3Config!.endPoint}${_s3Config!.bucketName}${_s3Config!.accessKey}");
    }
    final connectKey = "$id:$_selfDevId";
    var serverHost = appConfig.notificationServer.trimEnd('/');
    _wsChannel = WebSocketChannel.connect(Uri.parse('$serverHost/connect/$connectKey'));
    _wsChannel!.ready
        .then((_) async {
          Log.info(tag, "websocket connected");
          _wsPingTimer = Timer.periodic(Constants.defaultWsPingIntervalTime.s, (_) => _sendWsPing());
          if (!_loadingMissingData) {
            _loadMissingData();
          }
          for (var listener in _forwardStatusListener) {
            listener.onForwardServerConnected();
          }
          final list = await _client!.list(path: devicesInfoDir);
          final deviceIds = list.where((item) => item.isDir).map((item) => item.name).where((item) => item != _selfDevId).toList();
          for (var devId in deviceIds) {
            _sendOnLineMsg(devId);
          }
        })
        .catchError((err, stack) {
          Log.error(tag, err, stack);
        });
    _wsChannel!.stream.listen(
      _onWsMessage,
      onDone: () {
        Log.debug(tag, "ws done");
        for (var listener in _devAliveListeners) {
          for (var devId in _connectedDevIds) {
            listener.onDisconnected(devId);
          }
        }
        _connectedDevIds.clear();
        //如果为null表示手动断开，不重连
        //如果无网络，不重连
        if (_wsChannel != null || appConfig.currentNetWorkType.value != ConnectivityResult.none) {
          Future.delayed(1.s, connectWs);
        }
        for (var listener in _forwardStatusListener) {
          listener.onForwardServerDisconnected();
        }
      },
      onError: (err) {
        Log.error(tag, "ws $err");
      },
    );
  }

  Future<void> disconnectWs() async {
    try {
      final ws = _wsChannel;
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
      Log.error(tag, err, stack);
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
      Log.debug(tag, "_onWsMessage $json");
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
          Log.error(tag, "unknown ws data type, content = $json");
      }
    } catch (err, stack) {
      Log.error(tag, "_onWsMessage $err, $json", stack);
    }
  }

  ///执行设备连接操作（SocketService设备发现时不能执行）
  Future<bool> _connectDevices() async {
    if (_client == null) {
      Log.warn(tag, "storage client is null");
      return false;
    }
    final sktService = Get.find<SocketService>();
    if (sktService.discovering) {
      //正在设备发现，不能执行
      Log.warn(tag, "SocketService discovering");
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
      Log.warn(tag, "storage client is null");
      return;
    }
    final device = await getDeviceInfoFromCloud(devId);
    final version = await getDeviceVersionInfoFromCloud(devId);
    final minVersion = await getDeviceMinVersionInfoFromCloud(devId);
    if (device == null) {
      Log.warn(tag, "device is null, target dev id = $devId");
      return;
    }
    if (version == null) {
      Log.warn(tag, "version is null, target dev id = $devId");
      return;
    }
    if (minVersion == null) {
      Log.warn(tag, "minVersion is null, target dev id = $devId");
      return;
    }
    final isSocket = _registry.getProtocol(device.guid)?.isSocket ?? false;
    if (isSocket) {
      Log.warn(tag, "已通过Socket协议连接: ${device.guid}");
      return;
    }
    final result = await _addOrUpdateDevice(device);
    final isWebDav = _client is WebDavClient;
    final protocol = isWebDav ? TransportProtocol.webdav : TransportProtocol.s3;
    for (var listener in _devAliveListeners) {
      listener.onConnected(DevInfo.fromDevice(device), version, minVersion, protocol);
    }
    _registry.addDevice(DevInfo.fromDevice(device), protocol);
    await _sendOnLineMsg(devId);
    if (!result) {
      Log.warn(tag, "add or update device failed, device = $device");
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
          } catch (err, stack) {
            //ignore
          }
        }
      } catch (err, stack) {
        Log.error(tag, err, stack);
      }
    }

    //返回值未false代表未执行连接
    final ignored = !await _connectDevices();
    final devController = Get.find<DeviceController>();
    final connected = devController.onlineAndPairedList.where((item) => item.guid == msg.targetDevId).isNotEmpty;
    if (ignored && !connected) {
      _connectDevice(msg.targetDevId);
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
      Log.warn(tag, "storage client is null");
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
        Log.error(tag, "dev:$fromDevId not found");
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
        historyController.addData(history, false).whenComplete(() => syncingFile!.close(true));
        if (!await _client!.deleteFile(fileInfoStoragePath)) {
          Log.warn(tag, "delete storage file info failed! path = $fileInfoStoragePath");
        }
        if (!await _client!.deleteFile(storageFilePath)) {
          Log.warn(tag, "delete storage file failed! path = $storageFilePath");
        }
      } else {
        Log.warn(tag, "_processSyncFileMsg download file failed!. filePath = $storageFilePath, fileInfo = $json");
        syncingFile.close(false);
      }
    } catch (err, stack) {
      syncingFile?.close(false);
      Log.error(tag, "_processSyncFileMsg error: $err", stack);
    }
  }

  Future<void> _processAppInfoMsg(WsMsgData msg) async {
    if (_client == null) {
      Log.warn(tag, "storage client is null");
      return;
    }
    final id = msg.data;
    var dirPath = getAppInfoDirectoryPath(msg.targetDevId);
    var filePath = "$dirPath/$id";
    var bytes = await _client!.readFileBytes(filePath);
    if (bytes == null) {
      Log.warn(tag, "read file failed, path = $filePath");
      return;
    }
    await _syncData(msg.targetDevId, bytes, false);
  }

  Future<bool> _addOrUpdateDevice(Device dev) async {
    final dbDev = await dbService.deviceDao.getById(dev.guid, appConfig.userId);
    final devService = Get.find<DeviceService>();
    final isWebDav = _client is WebDavClient;
    final address = (isWebDav ? TransportProtocol.webdav : TransportProtocol.s3).name;
    final result = dbDev ?? dev;
    result.isPaired = true;
    result.address = address;
    return devService.addOrUpdate(result);
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
      Log.warn(tag, "storage client is null");
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
      _sendFile(dev!, key, today, data);
    } else {
      //获取module，根据 module 处理
      final module = Module.getValue(data["module"]);
      if (module == Module.appInfo) {
        //upload appInfo
        _uploadAppInfo(AppInfo.fromJson(jsonDecode(data["data"])));
        // return;
      }
      // 缓存数据，避免批量发送重复写入
      final hasData = _cache.contains(data);
      if (!hasData) {
        _cache.add(data);
        //缓存 10s
        Future.delayed(10.s, () => _cache.remove(data));
      }
      await _sendHistory(id, dev, key, today, data, hasData);
    }
  }

  ///从存储服务删除记录
  Future<void> deleteOpRecords(List<OperationRecord> records) async {
    if (_client == null) {
      Log.warn(tag, "storage client is null");
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
        Log.error(tag, "sync file create directory failed! storageDirPath = $storagePath");
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
      stream.listen(
        (bytes) => fileBytes.addAll(bytes),
        onDone: () async {
          //read all
          if (size != fileBytes.length) {
            //update sync file progress
            Log.warn(tag, "sync file failed. size ${fileBytes.length} != $size. path = $filePath, storagePath = $storageFilePath");
            syncingFile.setState(SyncingFileState.error);
            return;
          }
          syncingFile.setState(SyncingFileState.syncing);
          final result = await _client!.createFile(storageFilePath, Uint8List.fromList(fileBytes), onProgress: onStorageProgressSync);
          if (!result) {
            //update sync file progress
            Log.warn(tag, "sync file failed. path = $filePath, storagePath = $storageFilePath");
            syncingFile.setState(SyncingFileState.error);
          } else {
            //上传文件信息
            final result = await _client!.createFile(storageFileInfoPath, utf8.encode(jsonEncode(data)));
            if (!result) {
              await _client!.deleteFile(storageFilePath);
              Log.warn(tag, "sync file info failed. path = $storageFileInfoPath. filePath = $filePath");
              return;
            }
            //本地写入记录
            historyController.addData(history, false);
            //ws send
            _wsChannel?.sink.add(WsMsgData(WsMsgType.syncFile, "$today:$_selfDevId:$id", dev.guid).toString());
            syncingFile.setState(SyncingFileState.done);
          }
        },
      );
      //endregion
    } else {
      //region local file
      syncingFile.setState(SyncingFileState.syncing);
      final result = await _client!.uploadFile(storageFilePath, filePath, onProgress: onStorageProgressSync);
      if (!result) {
        //update sync file progress
        Log.warn(tag, "sync file failed. path = $filePath, storagePath = $storageFilePath");
        syncingFile.setState(SyncingFileState.error);
      } else {
        //上传文件信息
        final result = await _client!.createFile(storageFileInfoPath, utf8.encode(jsonEncode(data)));
        if (!result) {
          await _client!.deleteFile(storageFilePath);
          Log.warn(tag, "sync file info failed. path = $storageFileInfoPath. filePath = $filePath");
          return;
        }
        //本地写入记录
        historyController.addData(history, false);
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
          Log.warn(tag, "create history date directory failed! path = $path");
          return;
        }
      }
      var historyDirPath = getHistoryDatePath(_selfDevId, today);
      final path = "$historyDirPath/$id";
      final result = await _client!.createFile(path, m2.serialize(data));
      //写入存储服务，更新操作记录
      dbService.opRecordDao.updateStorageSyncStatus(id, result);
      if (!result) {
        Log.warn(tag, "StorageService write data failed! key=${key.name}, data = ${jsonEncode(data)}");
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

  //endregion

  //region BaseInfo getter

  Future<Device?> getDeviceInfoFromCloud(String devId) async {
    final bytes = await _client!.readFileBytes(getDeviceInfoPath(devId));
    if (bytes == null) return null;
    return Device.fromJson((jsonDecode(utf8.decode(bytes)) as Map<dynamic, dynamic>).cast());
  }

  Future<AppVersion?> getDeviceVersionInfoFromCloud(String devId) async {
    final bytes = await _client!.readFileBytes(getDeviceVersionPath(devId));
    if (bytes == null) return null;
    return AppVersion.fromJson((jsonDecode(utf8.decode(bytes)) as Map<dynamic, dynamic>).cast());
  }

  Future<AppVersion?> getDeviceMinVersionInfoFromCloud(String devId) async {
    final bytes = await _client!.readFileBytes(getDeviceMinVersionPath(devId));
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
    var interfaces = await NetworkInterface.list();
    var expendAddress = interfaces.map((networkInterface) => networkInterface.addresses).expand((ip) => ip);
    return expendAddress.where((ip) => ip.type == InternetAddressType.IPv4).map((address) => address.address).toList();
  }
}
