import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:clipshare/app/data/enums/connection_mode.dart';
import 'package:clipshare/app/data/enums/forward_msg_type.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/crypto.dart';
import 'package:clipshare/app/utils/extensions/string_extension.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import "package:msgpack_dart/msgpack_dart.dart" as m2;
import 'package:synchronized/synchronized.dart';

import 'data_packet_splitter.dart';

class SecureSocketClient {
  final String ip;
  late final int _port;

  int get port => _port;
  late final Socket _socket;
  bool _listening = false;
  bool _keyIsExchanged = false;
  late final void Function(SecureSocketClient)? _onConnected;
  late final void Function(SecureSocketClient client, Map<String, dynamic> data)? _onMessage;
  void Function(Exception e, SecureSocketClient client)? _onError;
  void Function(SecureSocketClient client)? _onDone;
  bool? _cancelOnError;
  final controller = StreamController<String>();
  late final Encrypter _encrypter;
  late final DiffieHellman _dh;
  late final String _aesKey;
  late final BigInt _prime1;
  late final BigInt _prime2;
  static const tag = "SecureSocketClient";
  late final String _targetDevId;
  late final String _selfDevId;
  late final ConnectionMode _connectionMode;
  final Lock _lock = Lock(); // 创建互斥锁
  bool _forwardReady = false;

  //使用compute的阈值
  static const int useComputeThreshold = 1024 * 100;

  bool get isReady => _keyIsExchanged;

  bool get isForwardMode => _connectionMode == ConnectionMode.forward;

  late final DataPacketSplitter _dataSplitter;
  final StreamController<String> _msgStreamController = StreamController();

  SecureSocketClient._private(this.ip);

  static SecureSocketClient empty = SecureSocketClient._private("127.0.0.1");

  ///连接 socket
  static Future<SecureSocketClient> connect({
    required String ip,
    required int port,
    required BigInt prime1,
    required BigInt prime2,
    ConnectionMode connectionMode = ConnectionMode.direct,
    String? targetDevId,
    String? selfDevId,
    void Function(SecureSocketClient)? onConnected,
    void Function(SecureSocketClient client, Map<String, dynamic> data)? onMessage,
    void Function(Exception e, SecureSocketClient client)? onError,
    void Function(SecureSocketClient client)? onDone,
    bool? cancelOnError,
  }) async {
    var socket = await Socket.connect(
      ip,
      port,
      timeout: const Duration(seconds: 2),
    );
    var ssc = SecureSocketClient.fromSocket(
      socket: socket,
      prime1: prime1,
      prime2: prime2,
      connectionMode: connectionMode,
      targetDevId: targetDevId,
      selfDevId: selfDevId,
      onConnected: onConnected,
      onMessage: onMessage,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
    if (ssc._connectionMode == ConnectionMode.direct) {
      //直连模式主动连接，发送素数，底数，公钥
      ssc.sendKey();
    } else {
      //中转模式发送初始信息
      ssc.send({
        "self": selfDevId,
        "target": targetDevId,
      });
    }
    return ssc;
  }

  factory SecureSocketClient.fromSocket({
    required Socket socket,
    required BigInt prime1,
    required BigInt prime2,
    ConnectionMode connectionMode = ConnectionMode.direct,
    String? targetDevId,
    String? selfDevId,
    int? serverPort,
    void Function(SecureSocketClient)? onConnected,
    required void Function(SecureSocketClient client, Map<String, dynamic> data)? onMessage,
    void Function(Exception e, SecureSocketClient client)? onError,
    void Function(SecureSocketClient client)? onDone,
    bool? cancelOnError,
  }) {
    final isForward = connectionMode == ConnectionMode.forward;
    if (isForward) {
      assert(targetDevId.isNotNullAndEmpty);
      assert(selfDevId.isNotNullAndEmpty);
    }
    var ssc = SecureSocketClient._private(socket.remoteAddress.address);
    if (serverPort != null) {
      ssc._port = serverPort;
    }
    ssc._connectionMode = connectionMode;
    if (connectionMode == ConnectionMode.forward) {
      ssc._targetDevId = targetDevId!;
      ssc._selfDevId = selfDevId!;
    }
    ssc._prime1 = prime1;
    ssc._prime2 = prime2;
    ssc._socket = socket;
    ssc._onMessage = onMessage;
    ssc._onConnected = onConnected;
    ssc._onError = onError;
    ssc._onDone = onDone;
    ssc._cancelOnError = cancelOnError;
    ssc._dataSplitter = DataPacketSplitter();
    ssc._listen();
    return ssc;
  }

  final _recDataLock = Lock();

  Future _onDataReceive(Uint8List bytes) async {
    try {
      if (isForwardMode && !_forwardReady) {
        //中转未准备好
        var json = jsonDecode(utf8.decode(bytes));
        var type = ForwardMsgType.getValue(json["type"]);
        Log.debug(tag, "forward ${type.name}");
        switch (type) {
          case ForwardMsgType.bothConnected:
            send({"type": ForwardMsgType.bothConnected.name});
            String sender = json["sender"];
            if (sender != _selfDevId) {
              _forwardReady = true;
            }
            break;
          case ForwardMsgType.forwardReady:
            _forwardReady = true;
            sendKey();
            break;
          default:
        }
      } else {
        //region 数据处理
        if (_keyIsExchanged) {
          //密钥已交换，此处需要解密
          Uint8List decrypt;
          if (bytes.length > useComputeThreshold) {
            decrypt = await compute(
              (List<dynamic> params) {
                return CryptoUtil.decryptAESAsBytes(
                  key: params[0],
                  encoded: params[2],
                  encrypter: params[1],
                );
              },
              [_aesKey, _encrypter, bytes],
            );
          } else {
            decrypt = CryptoUtil.decryptAESAsBytes(
              key: _aesKey,
              encoded: bytes,
              encrypter: _encrypter,
            );
          }
          if (_onMessage != null) {
            final map = m2.deserialize(decrypt);
            _onMessage(this, (map as Map<dynamic, dynamic>).cast<String, dynamic>());
          }
        } else {
          //密钥未交换
          _exchange(utf8.decode(bytes));
        }
        //endregion
      }
    } catch (ex, stack) {
      //解析出错
      Log.error(tag, "解析出错：$ex\n$stack");
    }
  }

  ///监听消息
  void _listen() {
    if (_listening) {
      throw Exception("SecureSocketService has started listening");
    }
    _listening = true;
    try {
      _socket.transform(_dataSplitter).listen(
        (bytes) {
          //接收完成，进行解码
          _recDataLock.synchronized(() => _onDataReceive(bytes));
        },
        onError: (e) {
          Log.error(tag, "error:$e");
          if (_onError != null) {
            _onError!(e, this);
          }
        },
        onDone: () {
          if (_keyIsExchanged) {
            _onDone?.call(this);
          }
          Log.debug(tag, "_onDone _keyIsExchanged $_keyIsExchanged");
          _socket.close();
        },
        cancelOnError: _cancelOnError,
      );
    } catch (e) {
      _listening = false;
      rethrow;
    }
  }

  ///密钥交换
  void _exchange(String msg) {
    var data = jsonDecode(msg);
    //A(client) -------> B(server)
    if (data["seq"] == 1) {
      //接收公钥，素数和底数g
      var key = data["key"];
      var g = BigInt.parse(data["g"]);
      var prime = BigInt.parse(data["prime"]);
      //使用素数，底数，自己的私钥创建一个DH对象
      _dh = DiffieHellman(prime, g, _prime2);
      //根据接收的公钥使用dh算法生成共享秘钥
      var otherPublicKey = BigInt.parse(key);
      //SharedSecretKey
      var ssk = _dh.generateSharedSecret(otherPublicKey);
      //计算 aesKey 完成密钥交换
      _aesKey = ssk.toString().substring(0, 32);
      _encrypter = CryptoUtil.getEncrypter(_aesKey);
      _port = data["port"];
      final appConfig = Get.find<ConfigService>();
      //发送自己的publicKey
      Map<String, dynamic> map = {
        "seq": 2,
        "key": _dh.publicKey.toString(),
        "port": appConfig.port,
      };
      //发送
      send(map);
    }
    //A(client) <------- B(server)
    if (data["seq"] == 2) {
      //接收公钥
      var key = data["key"];
      _port = data["port"];
      var otherPublicKey = BigInt.parse(key);
      //SharedSecretKey
      var ssk = _dh.generateSharedSecret(otherPublicKey);
      //计算 aesKey 完成密钥交换
      _aesKey = ssk.toString().substring(0, 32);
      _encrypter = CryptoUtil.getEncrypter(_aesKey);
    }
    _setKeyIsExchanged();
  }

  ///密钥已交换
  void _setKeyIsExchanged() {
    if (_keyIsExchanged) {
      throw Exception("already ready");
    }
    _keyIsExchanged = true;
    if (_onConnected != null) {
      _onConnected(this);
    }
  }

  ///发送数据
  Future<void> send(Map map) async {
    try {
      return _lock.synchronized(() async {
        final data = await _genSendData(map);
        // 计算总包数
        int maxPayloadSize = Constants.packetMaxPayloadSize;
        int packetSize = (data.length / maxPayloadSize).ceil();
        // 分包发送
        for (int i = 0; i < packetSize; i++) {
          // 计算当前包的数据范围
          int start = i * maxPayloadSize;
          int end = start + maxPayloadSize;
          if (end > data.length) end = data.length;
          // 当前包的数据（主体部分）
          Uint8List packetData = data.sublist(start, end);
          int payloadSize = packetData.length;
          // 创建包头
          Uint8List header = createPacketHeader(
            data.length,
            payloadSize,
            packetSize,
            i + 1,
          );
          // 组合头部和数据
          Uint8List packet = Uint8List(header.length + payloadSize);
          // 写入头部
          packet.setAll(0, header);
          // 写入载荷
          packet.setAll(header.length, packetData);
          //发送数据包
          _socket.add(packet);
          await _socket.flush();
        }
      });
    } catch (e, stack) {
      Log.debug(tag, "发送失败：$e");
      Log.debug(tag, "send, _onDone = ${_onDone == null}");
      Log.debug(tag, "$stack");
      if (_onDone != null) {
        _onDone!.call(this);
      }
    }
  }

  Future<Uint8List> _genSendData(Map map) async {
    Uint8List bytes = Uint8List(0);
    if (_keyIsExchanged) {
      final serialized = m2.serialize(map);
      if (serialized.length > useComputeThreshold) {
        bytes = await compute(
          (List<dynamic> params) {
            return CryptoUtil.encryptAESWithBytes(
              key: params[0],
              input: params[2],
              encrypter: params[1],
            );
          },
          [_aesKey, _encrypter, serialized],
        );
      } else {
        bytes = CryptoUtil.encryptAESWithBytes(
          key: _aesKey,
          input: serialized,
          encrypter: _encrypter,
        );
      }
    } else {
      bytes = utf8.encode(jsonEncode(map));
    }
    return bytes;
  }

  ///DH 算法发送 key 和 素数、底数
  void sendKey() {
    if (_keyIsExchanged) {
      throw Exception("already ready");
    }
    //底数g
    var g = BigInt.from(65537);
    //创建DH对象
    _dh = DiffieHellman(_prime1, g, _prime2);
    final appConfig = Get.find<ConfigService>();
    //发送素数，底数，公钥
    Map<String, dynamic> map = {
      "seq": 1,
      "prime": _prime1.toString(),
      "g": g.toString(),
      "key": _dh.publicKey.toString(),
      "port": appConfig.port,
    };
    send(map);
  }

  ///关闭连接
  Future close() {
    _msgStreamController.close();
    return _socket.close();
  }

  ///强制关闭
  void destroy() {
    _msgStreamController.close();
    return _socket.destroy();
  }

  static Uint8List createPacketHeader(
    int totalPayloadSize,
    int payloadSize,
    int packetSize,
    int seq,
  ) {
    var byteData = ByteData(Constants.packetHeaderSize);
    // 写入包大小（4字节）
    byteData.setUint32(0, totalPayloadSize, Endian.big);
    // 写入包大小（2字节）
    byteData.setUint16(4, payloadSize, Endian.big);
    // 写入总包数（2字节）
    byteData.setUint16(6, packetSize, Endian.big);
    // 写入当前包号（2字节）
    byteData.setUint16(8, seq, Endian.big);
    return byteData.buffer.asUint8List();
  }
}
