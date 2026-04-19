import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:clipshare/app/data/enums/forward_msg_type.dart';
import 'package:clipshare/app/data/models/end_point.dart';
import 'package:clipshare/app/data/models/foward_server_check_result.dart';
import 'package:clipshare/app/handlers/socket/_secure_socket_client.dart';
import 'package:clipshare/app/handlers/socket/data_packet_splitter.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/utils/extensions/string_extension.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

typedef OnForwardClientMessage =
    Future<void> Function(
      ForwardSocketClient self,
      ForwardMsgType msgType,
      Map<String, dynamic> data,
    );
typedef OnForwardClientDone = void Function(ForwardSocketClient client);
typedef OnForwardClientError =
    void Function(ForwardSocketClient client, Object e, StackTrace stack);

class ForwardSocketClient {
  static Map<String, dynamic> get baseMsg {
    final appConfig = Get.find<ConfigService>();
    return {
      "self": appConfig.device.guid,
      "devName": appConfig.localName,
      "platform": defaultTargetPlatform.name.upperFirst,
      "appVersion": appConfig.version.toString(),
    };
  }

  static const String tag = "ForwardSocketClient";

  late final EndPoint endPoint;

  String get host => endPoint.host;

  int get port => endPoint.port;

  bool _closed = false;

  bool get closed => _closed;

  late final Socket _socket;

  bool _listening = false;
  bool _inited = false;
  final _dataSplitter = DataPacketSplitter();

  ForwardServerCheckResult? _serverInfo;

  ForwardServerCheckResult? get serverInfo => _serverInfo;

  late final OnForwardClientMessage _onMessage;
  late final OnForwardClientError _onError;
  late final OnForwardClientDone _onDone;

  final Completer<ForwardSocketClient> _connectedCompleter = Completer();

  ForwardSocketClient._private(this.endPoint);

  static ForwardSocketClient empty = ForwardSocketClient._private(
    const EndPoint("127.0.0.1", 0),
  );

  static Future<ForwardSocketClient> connect({
    required EndPoint endPoint,
    required OnForwardClientMessage onMessage,
    required OnForwardClientError onError,
    required OnForwardClientDone onDone,
    String? key,
    Duration? timeout,
    bool checkOnly = false,
  }) async {
    timeout ??= const Duration(seconds: 2);
    final socket = await Socket.connect(
      endPoint.host,
      endPoint.port,
      timeout: timeout,
    );
    var fsc = ForwardSocketClient._private(endPoint);
    fsc._socket = socket;
    fsc._onMessage = onMessage;
    fsc._onError = onError;
    fsc._onDone = onDone;
    fsc._listen();
    await fsc._sendInitData(key: key);
    return fsc._connectedCompleter.future.timeout(timeout);
  }

  ///发送初始化数据
  Future<void> _sendInitData({bool checkOnly = false, String? key}) async {
    if (_inited) {
      throw 'Already initialized';
    }
    _inited = true;
    //中转服务器连接成功后发送本机信息
    final connData = ForwardSocketClient.baseMsg
      ..addAll({
        "connType": checkOnly
            ? ForwardConnType.check.name
            : ForwardConnType.base.name,
      });
    if (key != null) {
      connData["key"] = key;
    }
    await send(connData);
  }

  ///监听消息
  Future<void> _listen() async {
    if (_listening) {
      throw Exception("ForwardSocketClient has started listening");
    }
    _listening = true;
    try {
      var stream = _socket.transform(_dataSplitter);
      await for (var packet in stream) {
        try {
          final msg = (jsonDecode(utf8.decode(packet)) as Map<dynamic, dynamic>)
              .cast<String, dynamic>();
          final msgType = ForwardMsgType.getValue(msg["type"]);
          switch (msgType) {
            case ForwardMsgType.check:
              _onCheckMessage(msg);
              break;
            default:
              await _onMessage.call(this, msgType, msg);
          }
        } catch (err, stack) {
          Log.error(tag, "error:$err", stack);
          _onError.call(this, err, stack);
        }
      }
    } catch (err, stack) {
      _listening = false;
      Log.error(tag, "error:$err", stack);
      _onError.call(this, err, stack);
    } finally {
      Log.debug(tag, "onDone");
      // 尝试修复端口不释放的问题
      _socket.destroy();
      _closed = true;
      _onDone.call(this);
    }
  }

  void _onCheckMessage(Map<String, dynamic> json) {
    try {
      _serverInfo = ForwardServerCheckResult.fromJson(json);
      _connectedCompleter.complete(this);
    } catch (err, stack) {
      _connectedCompleter.completeError(err, stack);
    }
  }

  ///发送数据
  Future<void> send(Map map) async {
    try {
      //向中转服务器发送基本信息
      final payload = utf8.encode(jsonEncode(map));
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
      _socket.add(packet);
      await _socket.flush();
    } catch (e, stack) {
      Log.error(tag, "发送失败：$e", stack);
      await close();
    }
  }

  ///关闭连接
  Future close() async {
    try {
      await _socket.close();
    } catch (err, stack) {
      Log.error(tag, err, stack);
    } finally {
      _socket.destroy();
      _closed = true;
    }
  }

  static bool lessThan114(String? version) {
    if (version.isNullOrEmpty) {
      return true;
    }
    try {
      final versionParts = version!.split(".").map((p) => p.toInt()).toList();
      while (versionParts.length < 3) {
        versionParts.add(0);
      }
      final version114 = <int>[1, 1, 4];
      for (var i = 0; i < version114.length; i++) {
        if (version114[i] > versionParts[i]) {
          return true;
        }
      }
      return false;
    } catch (err, stack) {
      Log.error(tag, err, stack);
      return true;
    }
  }
}
