import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:clipshare/app/data/enums/forward_msg_type.dart';
import 'package:clipshare/app/handlers/socket/data_packet_splitter.dart';
import 'package:clipshare/app/handlers/socket/secure_socket_client.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/utils/extensions/number_extension.dart';
import 'package:clipshare/app/utils/extensions/string_extension.dart';
import 'package:clipshare/app/utils/extensions/time_extension.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

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

  final String ip;
  late final int _port;

  int get port => _port;
  late final Socket _socket;
  bool _enableHeartbeat = true;

  DateTime? _lastPingTime;
  Timer? _heartbeatTimer;
  bool _listening = false;
  late final void Function(ForwardSocketClient client, String data)? _onMessage;
  void Function(Exception e, ForwardSocketClient client)? _onError;
  void Function(ForwardSocketClient client)? _onDone;
  bool? _cancelOnError;
  late final StreamSubscription _stream;
  static const String tag = "ForwardSocketClient";

  ForwardSocketClient._private(this.ip);

  static ForwardSocketClient empty = ForwardSocketClient._private("127.0.0.1");

  ///连接 socket
  static Future<ForwardSocketClient> connect({
    required String ip,
    required int port,
    void Function(ForwardSocketClient)? onConnected,
    void Function(ForwardSocketClient client, String data)? onMessage,
    void Function(Exception e, ForwardSocketClient client)? onError,
    void Function(ForwardSocketClient client)? onDone,
    bool? cancelOnError,
    bool enableHeartbeat = true,
  }) async {
    var socket = await Socket.connect(
      ip,
      port,
      timeout: const Duration(seconds: 2),
    );
    var ssc = ForwardSocketClient.fromSocket(
      socket: socket,
      onMessage: onMessage,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
      enableHeartbeat: enableHeartbeat,
    );
    onConnected?.call(ssc);
    return ssc;
  }

  factory ForwardSocketClient.fromSocket({
    required Socket socket,
    int? serverPort,
    required void Function(ForwardSocketClient self, String data)? onMessage,
    void Function(Exception e, ForwardSocketClient self)? onError,
    void Function(ForwardSocketClient self)? onDone,
    bool? cancelOnError,
    bool enableHeartbeat = true,
  }) {
    var ssc = ForwardSocketClient._private(socket.remoteAddress.address);
    if (serverPort != null) {
      ssc._port = serverPort;
    }
    ssc._socket = socket;
    ssc._onMessage = onMessage;
    ssc._onError = onError;
    ssc._onDone = onDone;
    ssc._cancelOnError = cancelOnError;
    ssc._enableHeartbeat = enableHeartbeat;
    ssc._listen();
    if (enableHeartbeat) {
      ssc._startJudgeForwardClientAlivePeriod();
    }
    return ssc;
  }

  ///监听消息
  void _listen() {
    if (_listening) {
      throw Exception("ForwardSocketClient has started listening");
    }
    _listening = true;
    try {
      _stream = _socket
          .transform(DataPacketSplitter())
          .listen(
            (e) {
              var rec = utf8.decode(e);
              if (rec == '{"type":"ping"}') {
                _lastPingTime = DateTime.now();
                Log.debug(tag, "forward client ping, update pingTime = ${_lastPingTime!.format()}");
              } else {
                _onMessage?.call(this, rec);
              }
            },
            onError: (e) {
              Log.error(tag, "error:$e");
              if (_onError != null) {
                _onError!(e, this);
              }
            },
            onDone: () {
              _stopJudgeForwardClientAlive();
              _onDone?.call(this);
              Log.debug(tag, "_onDone");
              _socket.close();
            },
            cancelOnError: _cancelOnError,
          );
    } catch (e) {
      _listening = false;
      rethrow;
    }
  }

  ///发送数据
  void send(Map map) {
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
    } catch (e, stack) {
      Log.debug(tag, "发送失败：$e");
      Log.debug(tag, "_onDone ${_onDone == null}");
      Log.debug(tag, "$stack");
      if (_onDone != null) {
        _onDone!.call(this);
      }
    }
  }

  ///定时判断中转服务连接存活状态
  void _startJudgeForwardClientAlivePeriod() {
    if (!_enableHeartbeat) {
      return;
    }
    //先停止
    if (_heartbeatTimer != null) {
      _stopJudgeForwardClientAlive();
    }
    _lastPingTime = DateTime.now();
    //更新timer
    _heartbeatTimer = Timer.periodic(35.s, (timer) async {
      var disconnected = false;
      if (_lastPingTime == null) {
        disconnected = true;
        Log.debug(tag, "startJudgeForwardClientAlivePeriod _lastForwardServerPingTime is null");
      } else {
        final now = DateTime.now();
        if (now.difference(_lastPingTime!).inSeconds >= 35) {
          disconnected = true;
          Log.debug(tag, "startJudgeForwardClientAlivePeriod _lastForwardServerPingTime is ${_lastPingTime!.format()}");
        }
      }
      Log.debug(tag, "startJudgeForwardClientAlivePeriod disconnected: $disconnected");
      if (!disconnected) return;
      await close();
    });
  }

  ///停止定时判断中转服务连接存活状态
  void _stopJudgeForwardClientAlive() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _lastPingTime = null;
  }

  void enableHeartbeatTest() {
    if (_enableHeartbeat) {
      return;
    }
    _enableHeartbeat = true;
    if (_heartbeatTimer != null) {
      _startJudgeForwardClientAlivePeriod();
    }
  }

  void disableHeartbeatTest() {
    if (!_enableHeartbeat) {
      return;
    }
    _enableHeartbeat = false;
    _stopJudgeForwardClientAlive();
  }

  ///关闭连接
  Future close() {
    _stopJudgeForwardClientAlive();
    return _socket.close();
  }

}
