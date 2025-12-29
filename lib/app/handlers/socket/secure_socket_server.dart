import 'dart:async';
import 'dart:io';

import 'package:clipshare/app/handlers/socket/secure_socket_client.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:get/get.dart';

class SecureSocketServer {
  static const tag = "SecureSocketServer";
  final String ip;
  final int port;
  late final ServerSocket _server;
  bool _listening = false;
  late final void Function(String ip, int port) _onConnected;
  late final void Function(SecureSocketClient client, Map<String,dynamic> data) _onMessage;
  Function? _onError;
  void Function(
    Exception e,
    String ip,
    int port,
    SecureSocketClient client,
  )? _onClientError;
  void Function(
    String ip,
    int port,
    SecureSocketClient client,
  )? _onClientDone;
  void Function()? _onDone;
  bool? _cancelOnError;
  late final StreamSubscription _stream;
  final Set<SecureSocketClient> _sktList = {};

  SecureSocketServer._private(this.ip, this.port);

  ///服务端绑定监听端口
  static Future<SecureSocketServer> bind({
    required String ip,
    required int port,
    required void Function(String ip, int port) onConnected,
    required void Function(SecureSocketClient client, Map<String,dynamic> data) onMessage,
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
    void Function(Exception e, String ip, int port, SecureSocketClient client)?
        onClientError,
    void Function(String ip, int port, SecureSocketClient client)? onClientDone,
  }) async {
    var sss = SecureSocketServer._private(ip, port);
    sss._server = await ServerSocket.bind(ip, port);
    sss._onMessage = onMessage;
    sss._onError = onError;
    sss._onConnected = onConnected;
    sss._onDone = onDone;
    sss._onClientDone = onClientDone;
    sss._onClientError = onClientError;
    sss._listen();
    return sss;
  }

  ///监听新连接
  void _listen() {
    if (_listening) {
      throw Exception("SecureSocketService has started listening");
    }
    _listening = true;
    try {
      _stream = _server.listen(
        (client) {
          final appConfig = Get.find<ConfigService>();
          String ip = client.remoteAddress.address;
          //此处端口不是客户端的服务端口，是客户端的socket进程端口
          int port = client.remotePort;
          late SecureSocketClient ssc;
          ssc = SecureSocketClient.fromSocket(
            socket: client,
            prime1: appConfig.prime1,
            prime2: appConfig.prime2,
            dhAesKey: appConfig.dhAesKey,
            onConnected: (SecureSocketClient ssc) {
              _onConnected(ssc.ip, ssc.port);
            },
            onMessage: _onMessage,
            onDone: (SecureSocketClient client) {
              Log.debug(tag, "_onClientDone");
              if (_onClientDone != null) {
                _onClientDone!.call(ip, port, client);
              }
              if (_sktList.contains(ssc)) {
                _sktList.remove(ssc);
              }
            },
            onError: (e, SecureSocketClient client) {
              Log.error(tag, "_onClientError error:$e");
              if (_onClientError != null) {
                _onClientError!(e, ip, port, client);
              }
            },
            cancelOnError: _cancelOnError,
          );
          _sktList.add(ssc);
        },
        onError: (e, stack) {
          Log.error("SecureSocketServer", "error:$e");
          if (_onError != null) {
            _onError!(e);
          }
        },
        onDone: _onDone,
        cancelOnError: _cancelOnError,
      );
    } catch (e) {
      _listening = false;
      rethrow;
    }
  }

  ///发送数据
  void send(SecureSocketClient client, Map map) {
    client.send(map);
  }

  ///关闭连接
  Future close() {
    return _server.close();
  }
}
