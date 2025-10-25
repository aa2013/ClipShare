import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:clipshare/app/data/enums/forward_msg_type.dart';
import 'package:clipshare/app/data/enums/history_content_type.dart';
import 'package:clipshare/app/data/enums/msg_type.dart';
import 'package:clipshare/app/data/enums/syncing_file_state.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/models/dev_info.dart';
import 'package:clipshare/app/data/models/pending_file.dart';
import 'package:clipshare/app/data/models/syncing_file.dart';
import 'package:clipshare/app/data/repository/entity/tables/device.dart';
import 'package:clipshare/app/data/repository/entity/tables/history.dart';
import 'package:clipshare/app/handlers/socket/forward_socket_client.dart';
import 'package:clipshare/app/handlers/socket/secure_socket_client.dart';
import 'package:clipshare/app/modules/history_module/history_controller.dart';
import 'package:clipshare/app/services/channels/android_channel.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/services/transport/socket_service.dart';
import 'package:clipshare/app/services/syncing_file_progress_service.dart';
import 'package:clipshare/app/services/transport/storage_service.dart';
import 'package:clipshare/app/utils/extensions/device_extension.dart';
import 'package:clipshare/app/utils/extensions/file_extension.dart';
import 'package:clipshare/app/utils/extensions/number_extension.dart';
import 'package:clipshare/app/utils/extensions/time_extension.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:uri_file_reader/uri_file_reader.dart';

import '../../utils/log.dart';

class FileSyncHandler {
  static const tag = "FileSyncer";
  final appConfig = Get.find<ConfigService>();
  final dbService = Get.find<DbService>();
  final sktService = Get.find<SocketService>();
  final syncingFileService = Get.find<SyncingFileProgressService>();
  ServerSocket? _server;
  Socket? _forwardSkt;
  late final int _fileId;
  bool hasClient = false;
  File? _file;
  PendingFile pendingFile;
  late final BuildContext context;
  late final void Function() _onDone;
  late final bool isUri;

  FileSyncHandler._private({
    required this.pendingFile,
    required void Function(FileSyncHandler) onReady,
    required void Function() onDone,
    required this.context,
    bool useForward = false,
    String? targetDevId,
  }) {
    _fileId = appConfig.snowflake.nextId();
    _onDone = onDone;
    isUri = pendingFile.isUri;
    if (!isUri) {
      final path = pendingFile.filePath;
      _file = File(path);
      if (!_file!.existsSync()) {
        throw Exception("file not found: $path");
      }
    }
    if (useForward) {
      //检查中转设置
      var host = sktService.forwardServerHost;
      var port = sktService.forwardServerPort;
      var forwardEnabled = appConfig.enableForward;
      if (!forwardEnabled || host == null || port == null) {
        throw Exception("Forwarding service not enabled.");
      }
      //连接中转服务器
      Socket.connect(host, port).then((skt) async {
        final fileName = isUri ? pendingFile.fileName : _file!.fileName;
        final size = isUri ? pendingFile.size : await _file!.length();
        _forwardSkt = skt;
        var baseMsg = ForwardSocketClient.baseMsg;
        //向中转服务器发送基本信息
        final payload = utf8.encode(
          json.encode(
            baseMsg..addAll({
              "fileName": fileName,
              "size": size.toString(),
              "fileId": _fileId.toString(),
              "target": targetDevId!,
              "connType": ForwardConnType.sendFile.name,
              "userId": appConfig.userId.toString(),
            }),
          ),
        );
        final msgSize = payload.length;
        final header = SecureSocketClient.createPacketHeader(
          msgSize,
          msgSize,
          1,
          1,
        );
        // 组合头部和载荷
        Uint8List packet = Uint8List(header.length + payload.length);
        // 写入头部
        packet.setAll(0, header);
        // 写入载荷
        packet.setAll(header.length, payload);
        //写入数据
        skt.add(packet);
      });
      //告知 SocketService
      sktService.addSendFileRecordByForward(this, _fileId);
      //延时检测是否有客户端连接，超时取消发送
      _delayedClientCheck(() {
        _onDone();
        sktService.removeSendFileRecordByForward(this, _fileId, targetDevId!);
      });
    } else {
      ServerSocket.bind(InternetAddress.anyIPv4, 0).then((server) {
        _server = server;
        onReady(this);
        _server!.listen((client) async {
          hasClient = true;
          try {
            //向客户端发送文件
            sendFile2Socket(client);
          } catch (err, stack) {
            Log.error(tag, "$err,$stack");
            hasClient = false;
            client.close();
            _server?.close();
          }
        });
        _delayedClientCheck(_onDone);
      });
    }
  }

  ///当文件接收方连接了中转服务器后由 SocketService 调用该方法通知发送端开始发送
  void onForwardReceiverConnected() {
    sktService.removeSendFileRecordByForward(this, _fileId, null);
    hasClient = true;
    try {
      //向 中转服务器 发送文件
      sendFile2Socket(_forwardSkt!);
    } catch (err, stack) {
      Log.error(tag, "$err,$stack");
    }
  }

  ///向 socket 发送文件
  Future<void> sendFile2Socket(Socket client) async {
    DateTime start = DateTime.now();
    final filePath = isUri ? pendingFile.filePath : _file!.normalizePath;
    final fileSize = isUri ? pendingFile.size! : _file!.lengthSync();
    final fileName = isUri ? pendingFile.fileName : _file!.fileName;
    final syncingFile = SyncingFile(
      totalSize: fileSize,
      context: context,
      filePath: filePath,
      fromDev: appConfig.device,
      isSender: true,
      startTime: DateTime.now().format(),
      onClose: (done) {
        if (done) {
          return;
        }
        client.destroy();
        syncingFileService.removeSyncingFile(filePath);
      },
    );
    syncingFileService.updateSyncingFile(syncingFile);
    Stream<List<int>> stream;
    if (isUri) {
      final nullableStream = await uriFileReader.readFileAsBytesStream(pendingFile.filePath);
      if (nullableStream == null) {
        Global.showSnackBarWarn(text: TranslationKey.failedToLoad.tr);
        throw TranslationKey.failedToLoad.tr;
      }
      stream = nullableStream.transform(
        StreamTransformer<Uint8List, List<int>>.fromHandlers(
          handleData: (data, sink) {
            syncingFile.addBytes(data);
            sink.add(data);
          },
        ),
      );
    } else {
      stream = _file!.openRead().transform(
        StreamTransformer<List<int>, List<int>>.fromHandlers(
          handleData: (data, sink) {
            syncingFile.addBytes(data);
            sink.add(data);
          },
        ),
      );
    }
    syncingFile.setState(SyncingFileState.syncing);
    client
        .addStream(stream)
        .then((value) {
          var path = filePath;
          try {
            path = Uri.decodeComponent(filePath);
          } catch (err, stack) {
            //ignored
          }
          var history = History(
            id: _fileId,
            uid: appConfig.userId,
            devId: appConfig.devInfo.guid,
            time: start.toString(),
            content: path,
            type: HistoryContentType.file.value,
            size: fileSize,
            sync: true,
          );
          final historyController = Get.find<HistoryController>();
          historyController.addData(history, false);
          syncingFile.setState(SyncingFileState.done);
        })
        .catchError((err, stack) {
          syncingFile.setState(SyncingFileState.error);
          Log.error(tag, "send file failed: $filePath. $err $stack");
        })
        .whenComplete(() {
          Log.info(tag, "send file($fileName) completed");
          client.close();
          _server?.close();
          _onDone();
        });
  }

  ///在一定时间后检查是否有客户端连接，若无客户端则关闭服务
  void _delayedClientCheck(void Function() onDone) {
    Future.delayed(5.s, () {
      if (hasClient) return;
      Log.info(tag, "No client connection for more than 5 seconds");
      _server?.close();
      _forwardSkt?.close();
      onDone();
    });
  }

  //region 静态方法接收和发送文件

  ///给多个设备发送多个文件
  ///[devices] 发送的设备列表
  ///[files] 发送的文件列表
  ///[i] 发送第几个文件
  static void sendFiles({
    required List<Device> devices,
    required List<PendingFile> files,
    required BuildContext context,
    int i = 0,
  }) {
    if (i >= devices.length) {
      return;
    }
    //给每个设备发送文件
    _sendDevFiles(
      device: devices[i],
      paths: files,
      context: context,
      //发完一个设备后给下一个设备发送
      onDone: () => sendFiles(
        devices: devices,
        files: files,
        i: i + 1,
        context: context,
      ),
    );
  }

  ///给设备发送多个文件
  ///[device] 发送的设备
  ///[paths] 发送的文件列表
  ///[onDone] 发送完成事件
  ///[i] 发送第几个文件
  static void _sendDevFiles({
    required Device device,
    required List<PendingFile> paths,
    required void Function() onDone,
    required BuildContext context,
    int i = 0,
  }) {
    if (i >= paths.length) {
      onDone();
      return;
    }
    _sendFile(
      device: device,
      pendingFile: paths[i],
      context: context,
      //发完一个文件后给设备发送下一个文件
      onDone: () => _sendDevFiles(
        device: device,
        paths: paths,
        onDone: onDone,
        i: i + 1,
        context: context,
      ),
    );
  }

  ///发送文件
  ///[device] 发送的设备
  ///[pendingFile] 发送的文件地址
  static void _sendFile({
    required Device device,
    required PendingFile pendingFile,
    required void Function() onDone,
    required BuildContext context,
  }) async {
    int totalSize;
    String fileName;
    if (pendingFile.isUri) {
      totalSize = pendingFile.size!;
      fileName = pendingFile.fileName!;
    } else {
      final file = File(pendingFile.filePath);
      totalSize = await file.length();
      fileName = file.fileName;
    }
    //如果存在多级文件夹就拼接上文件夹
    if (pendingFile.directories.isNotEmpty) {
      fileName = "${pendingFile.directories.join("/")}/$fileName";
    }
    if (device.isUseStorage) {
      final storageService = Get.find<StorageService>();
      final appConfig = Get.find<ConfigService>();
      storageService.sendData(DevInfo.fromDevice(device), MsgType.file, {
        "fileId": appConfig.snowflake.nextId(),
        "filePath": pendingFile.filePath,
        "fileName": fileName,
        "isUri": pendingFile.isUri,
        "size": totalSize,
      });
    } else {
      final sktService = Get.find<SocketService>();
      final useForward = sktService.isUseForward(device.guid);
      FileSyncHandler._private(
        pendingFile: pendingFile,
        context: context,
        useForward: useForward,
        targetDevId: useForward ? device.guid : null,
        onReady: (syncer) async {
          device.sendData(MsgType.file, {
            "fileName": fileName,
            "size": totalSize,
            "port": syncer._server?.port,
            "fileId": syncer._fileId,
          });
        },
        onDone: onDone,
      );
    }
  }

  static Future<void> receiveFile({
    required String ip,
    required int port,
    required int size,
    required String fileName,
    required String devId,
    required int userId,
    required int fileId,
    required BuildContext context,
    bool isForward = false,
    String? targetId,
  }) async {
    //中转模式下targetId不能为null
    assert(!isForward || targetId != null);
    final dbService = Get.find<DbService>();
    final appConfig = Get.find<ConfigService>();
    Device? dev = await dbService.deviceDao.getById(devId, appConfig.userId);
    if (dev == null) {
      Log.error(tag, "dev:$devId not found");
      return;
    }
    var socket = await Socket.connect(ip, port);
    String filePath = "${appConfig.fileStorePath}/$fileName";
    File file = File(filePath);
    Log.debug(tag, "receive file $filePath");
    final dir = file.parent;
    //如果父级文件夹不存在则创建
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    ///文件存在处理策略
    while (file.existsSync()) {
      //如果文件存在，给文件加后缀
      final seqName = file.buildDuplicateSeqName();
      filePath = "${appConfig.fileStorePath}/$seqName";
      file = File(filePath);
    }
    final syncingFileService = Get.find<SyncingFileProgressService>();
    final syncingFile = SyncingFile(
      totalSize: size,
      context: context,
      filePath: filePath,
      fromDev: dev,
      sink: file.openWrite(),
      isSender: false,
      startTime: DateTime.now().format("yyyy-MM-dd HH:mm:ss"),
      onClose: (done) {
        if (done) {
          return;
        }
        socket.destroy();
        syncingFileService.removeSyncingFile(filePath);
      },
    );
    syncingFileService.updateSyncingFile(syncingFile);
    var start = DateTime.now();
    if (isForward) {
      //告知发送方接收方已经连接
      Map<String, String> data = {
        "connType": ForwardConnType.recFile.name,
        "target": targetId!,
        "fileId": fileId.toString(),
        "self": appConfig.device.guid,
      };
      final payload = utf8.encode(json.encode(data));
      final msgSize = payload.length;
      final header = SecureSocketClient.createPacketHeader(
        msgSize,
        msgSize,
        1,
        1,
      );
      // 组合头部和载荷
      Uint8List packet = Uint8List(header.length + payload.length);
      // 写入头部
      packet.setAll(0, header);
      // 写入载荷
      packet.setAll(header.length, payload);
      //写入数据
      socket.add(packet);
    }
    socket.listen(
      (bytes) {
        syncingFile.addBytes(bytes);
      },
      onError: (err, stack) {
        Log.error(tag, "receive file failed. $err $stack");
        file.delete();
        syncingFile.close(false);
      },
      cancelOnError: true,
      onDone: () {
        var end = DateTime.now();
        int offset = max(end.difference(start).inSeconds, 1);
        int speed = size ~/ offset;
        Log.info(
          tag,
          "onDone $offset seconds, size: ${size.sizeStr}, speed: ${speed.sizeStr}/s",
        );
        var history = History(
          id: fileId,
          uid: userId,
          devId: devId,
          time: start.toString(),
          content: filePath,
          type: HistoryContentType.file.value,
          size: size,
          sync: true,
        );
        final historyController = Get.find<HistoryController>();
        historyController.addData(history, false).whenComplete(() => syncingFile.close(true));
        if (file.isMediaFile) {
          //媒体文件，刷新媒体库
          if (Platform.isAndroid) {
            var androidChannelService = Get.find<AndroidChannelService>();
            androidChannelService.notifyMediaScan(filePath);
          }
        }
      },
    );
  }

  //endregion
}
