import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:clipshare/app/data/enums/connection_mode.dart';
import 'package:clipshare/app/data/enums/forward_msg_type.dart';
import 'package:clipshare/app/data/enums/msg_type.dart';
import 'package:clipshare/app/data/models/dev_info.dart';
import 'package:clipshare/app/data/models/end_point.dart';
import 'package:clipshare/app/data/models/message_data.dart';
import 'package:clipshare/app/data/models/version.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
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

typedef OnSecureSocketClientMessage = FutureOr<void> Function(SecureSocketClient client, MessageData data);

typedef OnSecureSocketClientError = FutureOr<void> Function(SecureSocketClient client, Object e, StackTrace trace);

typedef OnSecureSocketClientDone = FutureOr<void> Function(SecureSocketClient client);

typedef OnDeviceForget = FutureOr<void> Function(SecureSocketClient client);

class SecureSocketClient {
  static const tag = "SecureSocketClient";
  final deviceDao = Get.find<DbService>().deviceDao;
  final appConfig = Get.find<ConfigService>();

  //使用compute的阈值
  static const int useComputeThreshold = 1024 * 100;

  final EndPoint _endPoint;

  String get host => _endPoint.host;

  int get port => _endPoint.port;
  late final Socket _socket;

  int get localPort => _socket.port;

  String? _dhAesKey;
  late final Encrypter _encrypter;
  Encrypter? _dhEncrypter;
  late final DiffieHellman _dh;
  late final String _aesKey;

  late final AppVersion version;

  late final AppVersion minVersion;

  bool _isPaired = false;

  bool get isPaired => _isPaired;

  bool _isClosedByUser = false;

  bool get isClosedByUser => _isClosedByUser;

  bool _closed = false;

  bool get closed => _closed;

  var _listening = false;

  late final String _selfDevId;
  String? _targetDevId;

  late final ConnectionMode _connectionMode;

  bool _forwardReady = false;
  bool _keyIsExchanged = false;

  bool get isForwardMode => _connectionMode == ConnectionMode.forward;

  final DataPacketSplitter _dataSplitter = DataPacketSplitter();

  final Completer<SecureSocketClient> _connectedCompleter = Completer();

  Completer<void>? _testOnlineCompleter;

  late final OnSecureSocketClientMessage _onMessage;
  late final OnSecureSocketClientDone _onDone;
  late final OnSecureSocketClientError? _onError;
  late final OnDeviceForget _onDeviceForget;

  late final DevInfo _devInfo;

  DevInfo get devInfo => _devInfo;

  SecureSocketClient._private(this._endPoint);

  static Future<SecureSocketClient> createFromEndPoint({
    required EndPoint endPoint,
    required OnSecureSocketClientMessage onMessage,
    required OnSecureSocketClientDone onDone,
    required OnDeviceForget onDeviceForget,
    OnSecureSocketClientError? onError,
    ConnectionMode connectionMode = ConnectionMode.direct,
    String? selfDevId,
    String? targetDevId,
    bool? cancelOnError,
    Duration? timeout,
  }) async {
    final socket = await Socket.connect(endPoint.host, endPoint.port, timeout: const Duration(seconds: 2));
    return _createFromSocket(
      socket: socket,
      onMessage: onMessage,
      onDone: onDone,
      onDeviceForget: onDeviceForget,
      isSender: true,
      onError: onError,
      connectionMode: connectionMode,
      selfDevId: selfDevId,
      targetDevId: targetDevId,
      cancelOnError: cancelOnError,
      timeout: timeout,
    );
  }

  static Future<SecureSocketClient> createFromSocket({
    required Socket socket,
    required OnSecureSocketClientMessage onMessage,
    required OnSecureSocketClientDone onDone,
    required OnDeviceForget onDeviceForget,
    OnSecureSocketClientError? onError,
    ConnectionMode connectionMode = ConnectionMode.direct,
    String? selfDevId,
    String? targetDevId,
    bool? cancelOnError,
    Duration? timeout,
  }) async {
    return _createFromSocket(
      socket: socket,
      onMessage: onMessage,
      onDone: onDone,
      onDeviceForget: onDeviceForget,
      isSender: false,
      onError: onError,
      connectionMode: connectionMode,
      selfDevId: selfDevId,
      targetDevId: targetDevId,
      cancelOnError: cancelOnError,
      timeout: timeout,
    );
  }

  static Future<SecureSocketClient> _createFromSocket({
    required Socket socket,
    required OnSecureSocketClientMessage onMessage,
    required OnSecureSocketClientDone onDone,
    required OnDeviceForget onDeviceForget,
    required bool isSender,
    OnSecureSocketClientError? onError,
    ConnectionMode connectionMode = ConnectionMode.direct,
    String? selfDevId,
    String? targetDevId,
    bool? cancelOnError,
    Duration? timeout,
  }) async {
    final isForward = connectionMode == ConnectionMode.forward;
    if (isForward) {
      assert(targetDevId.isNotNullAndEmpty);
      assert(selfDevId.isNotNullAndEmpty);
    }
    var ssc = SecureSocketClient._private(
      EndPoint(socket.remoteAddress.address, socket.remotePort),
    );
    final appConfig = ssc.appConfig;
    timeout ??= const Duration(seconds: 2);
    final dhAesKey = appConfig.dhAesKey;
    if (dhAesKey != null) {
      ssc._dhEncrypter = CryptoUtil.getEncrypter(dhAesKey);
    }
    ssc._connectionMode = connectionMode;
    if (isForward) {
      ssc._selfDevId = selfDevId!;
      ssc._targetDevId = targetDevId!;
    }
    ssc._socket = socket;
    ssc._onDone = onDone;
    ssc._onMessage = onMessage;
    ssc._onDeviceForget = onDeviceForget;
    ssc._onError = onError;
    ssc._dhAesKey = appConfig.dhAesKey;
    ssc._listen();
    await ssc._sendInitData(isSender);
    return ssc._connectedCompleter.future.timeout(timeout);
  }

  ///监听消息
  Future<void> _listen() async {
    if (_listening) {
      throw Exception("SecureSocketService has started listening");
    }
    _listening = true;
    try {
      var stream = _socket.transform(_dataSplitter);
      await for (var packet in stream) {
        try {
          if (isForwardMode && !_forwardReady) {
            //中转未准备好
            await _onForwardUnReady(packet);
            continue;
          }
          //直连或者中转已准备好
          if (_keyIsExchanged) {
            //密钥已交换，解析消息内容
            await _resolveMessagePacket(packet);
          } else {
            //密钥未交换
            await _exchange(packet);
          }
        } catch (err, stack) {
          Log.error(tag, err, stack);
        }
      }
    } catch (err, stack) {
      await _onError?.call(this, err, stack);
      Log.error(tag, err, stack);
    } finally {
      _closed = true;
      await _onDone(this);
    }
  }

  ///中转未准备好
  Future<void> _onForwardUnReady(Uint8List packet) async {
    var json = jsonDecode(utf8.decode(packet));
    var type = ForwardMsgType.getValue(json["type"]);
    Log.debug(tag, "forward ${type.name}");
    switch (type) {
      case ForwardMsgType.bothConnected:
        String sender = json["sender"];
        if (sender != _selfDevId) {
          _forwardReady = true;
        }
        await send({"type": ForwardMsgType.bothConnected.name});
        break;
      case ForwardMsgType.forwardReady:
        _forwardReady = true;
        await sendKey();
        break;
      default:
    }
  }

  ///密钥未交换
  Future<void> _resolveMessagePacket(Uint8List packet) async {
    Uint8List decrypt;
    if (packet.length > useComputeThreshold) {
      decrypt = await compute(
        (List<dynamic> params) {
          return CryptoUtil.decryptAESAsBytes(
            key: params[0],
            encoded: params[2],
            encrypter: params[1],
          );
        },
        [_aesKey, _encrypter, packet],
      );
    } else {
      decrypt = CryptoUtil.decryptAESAsBytes(
        key: _aesKey,
        encoded: packet,
        encrypter: _encrypter,
      );
    }
    final map = (m2.deserialize(decrypt) as Map<dynamic, dynamic>).cast<String, dynamic>();
    final msgData = MessageData.fromJson(map);
    Log.debug(tag, "receive msg, devName = ${msgData.send.name} type: ${msgData.key}");
    if (_connectedCompleter.isCompleted) {
      if (msgData.key == MsgType.ping) {
        if (msgData.data.containsKey("result")) {
          await _onMsgPingRequestResult(msgData);
        }
      } else if (msgData.key == MsgType.pingResult) {
        _onMsgPingResult(msgData);
      } else if (msgData.key == MsgType.disConnect) {
        //主动断开连接
        _isClosedByUser = true;
        await close();
      } else if (msgData.key == MsgType.forgetDev) {
        _isPaired = false;
        await _onDeviceForget(this);
      } else if (msgData.key != MsgType.pairedStatus) {
        //设备信息已获得
        await _onMessage(this, msgData);
      }
    } else {
      if (msgData.key == MsgType.connect) {
        await _onMsgConnect(msgData);
      }
      if (msgData.key == MsgType.pairedStatus) {
        await _onMsgPairedStatus(msgData);
        _connectedCompleter.complete(this);
      } else {
        final error = Exception('not supported MsgType ${msgData.key} before connected');
        _connectedCompleter.completeError(error);
      }
    }
  }

  ///收到连接请求
  Future<void> _onMsgConnect(MessageData msgData) async {
    _devInfo = msgData.send;
    var device = await deviceDao.getById(_devInfo!.guid, 0);
    var isPaired = device?.isPaired ?? false;
    var pairedStatusData = MessageData(
      userId: 0,
      send: appConfig.devInfo,
      key: MsgType.pairedStatus,
      data: {
        "isPaired": isPaired,
        "minVersionName": appConfig.minVersion.name,
        "minVersionCode": appConfig.minVersion.code,
        "versionName": appConfig.version.name,
        "versionCode": appConfig.version.code,
      },
    );
    await send(pairedStatusData.toJson());
  }

  ///收到对方配对状态
  Future<void> _onMsgPairedStatus(MessageData msgData) async {
    final dev = msgData.send;
    var device = await deviceDao.getById(dev.guid, 0);
    bool paired = false;
    if (device != null) {
      var localIsPaired = device.isPaired;
      var remoteIsPaired = msgData.data["isPaired"];
      //双方配对信息一致
      if (remoteIsPaired && localIsPaired) {
        paired = true;
        Log.debug(tag, "${dev.name} has paired");
      }
    }
    //告诉客户端配对状态
    var pairedStatusData = MessageData(
      userId: 0,
      send: appConfig.devInfo,
      key: MsgType.pairedStatus,
      data: {
        "isPaired": paired,
        "minVersionName": appConfig.minVersion.name,
        "minVersionCode": appConfig.minVersion.code,
        "versionName": appConfig.version.name,
        "versionCode": appConfig.version.code,
      },
    );
    await send(pairedStatusData.toJson());
    var minName = msgData.data["minVersionName"];
    var minCode = msgData.data["minVersionCode"];
    var versionName = msgData.data["versionName"];
    var versionCode = msgData.data["versionCode"];
    var minVersion = AppVersion(minName, minCode);
    var version = AppVersion(versionName, versionCode);
    Log.debug(tag, "minVersion $minVersion version $version");
    this.version = version;
    this.minVersion = minVersion;
    _isPaired = paired;
    _devInfo = msgData.send;
  }

  ///收到 ping 结果
  void _onMsgPingResult(MessageData msgData) {
    _testOnlineCompleter?.complete();
    _testOnlineCompleter = null;
  }

  ///收到 ping 消息且需要返回结果
  Future<void> _onMsgPingRequestResult(MessageData msgData) async {
    final msg = MessageData(
      userId: 0,
      send: appConfig.devInfo,
      key: MsgType.pingResult,
      data: {},
      recv: null,
    );
    await send(msg.toJson());
  }

  ///测试连接有效性
  Future<bool> testOnline([Duration? timeout]) async {
    if (_testOnlineCompleter != null) {
      Log.warn(tag, "_testOnlineCompleter is not null");
      return false;
    }
    _testOnlineCompleter = Completer();
    try {
      timeout ??= const Duration(seconds: 2);
      //发送一个ping事件，但是要求对方给回复
      final msg = MessageData(
        userId: 0,
        send: appConfig.devInfo,
        key: MsgType.ping,
        data: {
          "result": null,
        },
        recv: null,
      );
      await send(msg.toJson());
      await _testOnlineCompleter!.future.timeout(timeout);
      return true;
    } catch (err, stack) {
      Log.error(tag, err, stack);
      return false;
    }
  }

  ///region DH密钥交换

  ///发送初始数据
  Future<void> _sendInitData(bool isSender) async {
    if (isForwardMode) {
      //中转模式发送初始信息
      await send({
        "self": _selfDevId,
        "target": _targetDevId,
      });
    } else {
      if (isSender) {
        //直连模式主动连接，发送素数，底数，公钥
        await sendKey();
      }
    }
  }

  ///DH 算法发送 key 和 素数、底数
  Future<void> sendKey() async {
    if (_keyIsExchanged) {
      throw Exception("already exchanged");
    }
    //底数g
    var g = BigInt.from(65537);
    //创建DH对象
    _dh = DiffieHellman(appConfig.prime1, g, appConfig.prime2);
    //发送素数，底数，公钥
    Map<String, dynamic> map = {
      "seq": 1,
      "prime": _dhEncrypt(appConfig.prime1.toString()),
      "g": _dhEncrypt(g.toString()),
      "key": _dhEncrypt(_dh.publicKey.toString()),
      "port": appConfig.port,
    };
    await send(map);
  }

  ///密钥交换
  Future<void> _exchange(Uint8List packet) async {
    var data = jsonDecode(utf8.decode(packet));
    final seq = data["seq"];
    //A(client) -------> B(server)
    if (seq == 1) {
      //接收公钥，素数和底数g
      var key = _dhDecrypt(data["key"]);
      var g = BigInt.parse(_dhDecrypt(data["g"]));
      var prime = BigInt.parse(_dhDecrypt(data["prime"]));
      //使用素数，底数，自己的私钥创建一个DH对象
      _dh = DiffieHellman(prime, g, appConfig.prime2);
      //根据接收的公钥使用dh算法生成共享秘钥
      var otherPublicKey = BigInt.parse(key);
      //SharedSecretKey
      var ssk = _dh.generateSharedSecret(otherPublicKey);
      //计算 aesKey 完成密钥交换
      _aesKey = ssk.toString().substring(0, 32);
      _encrypter = CryptoUtil.getEncrypter(_aesKey);
      //发送自己的publicKey
      Map<String, dynamic> map = {
        "seq": 2,
        "key": _dhEncrypt(_dh.publicKey.toString()),
        "port": appConfig.port,
      };
      //发送
      await send(map);
    }
    //A(client) <------- B(server)
    if (seq == 2) {
      //接收公钥
      var key = _dhDecrypt(data["key"]);
      var otherPublicKey = BigInt.parse(key);
      //SharedSecretKey
      var ssk = _dh.generateSharedSecret(otherPublicKey);
      //计算 aesKey 完成密钥交换
      _aesKey = ssk.toString().substring(0, 32);
      _encrypter = CryptoUtil.getEncrypter(_aesKey);
    }
    if (_keyIsExchanged) {
      throw Exception("already ready");
    }
    _keyIsExchanged = true;
  }

  ///DH 参数加密
  String _dhEncrypt(String content) {
    if (_dhAesKey.isNullOrEmpty) {
      return content;
    }
    return CryptoUtil.encryptAES(
      key: _dhAesKey!,
      input: content,
      encrypter: _dhEncrypter,
    );
  }

  ///DH 参数解密
  String _dhDecrypt(String encrypted) {
    if (_dhAesKey.isNullOrEmpty) {
      return encrypted;
    }
    return CryptoUtil.decryptAES(
      key: _dhAesKey!,
      encoded: encrypted,
      encrypter: _dhEncrypter,
    );
  }

  ///endregion

  ///region 数据发送

  final Lock _lock = Lock();

  Future<void> send(Map<String, dynamic> map) async {
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
      Log.error(tag, "发送失败：$e", stack);
      await close();
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

  ///endregion

  ///关闭连接
  Future<void> close() async {
    try {
      await _socket.close();
    } finally {
      //有时会出现连接关闭后一直 TIME_WAIT 状态占用端口，需要手动 destroy
      _socket.destroy();
      _closed = true;
    }
  }
}
