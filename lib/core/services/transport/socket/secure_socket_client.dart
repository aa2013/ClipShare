import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:clipshare/core/constants/network_constants.dart';
import 'package:clipshare/core/database/tables/device.dart';
import 'package:clipshare/core/services/device/local_device_info.dart';
import 'package:clipshare/core/services/transport/enums/msg_type.dart';
import 'package:clipshare/shared/extensions/string_extension.dart';
import 'package:clipshare/shared/models/version.dart';
import 'package:clipshare/shared/utils/crypto.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:clipshare/shared/utils/parallerl_task.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter/foundation.dart';
import 'package:msgpack_dart/msgpack_dart.dart' as m2;
import 'package:synchronized/synchronized.dart';

import '../enums/connection_mode.dart';
import '../enums/forward_msg_type.dart';
import '../enums/socket_connection_state.dart';
import '../models/local_socket_base_info.dart';
import '../models/message_data.dart';
import 'data_packet_splitter.dart';

class SecureSocketClient {
  static const String tag = 'SecureSocketClient';

  // 使用 compute 的阈值，超过该大小时避免加解密阻塞 UI isolate。
  static const int useComputeThreshold = 1024 * 100;

  /// 远端 IP；中转模式下是中转服务器 IP，设备身份以握手 devInfo 为准。
  final String ip;

  /// 远端业务端口，DH 第一步会同步真实 Socket 服务端口。
  late int _port;

  ///本机基础信息
  late LocalSocketBaseInfo _baseInfo;

  /// 底层 TCP Socket，只能由本类关闭和销毁。
  late final Socket _socket;

  /// 当前连接来源，决定是否需要先走中转准备消息。
  late final ConnectionMode _connectionMode;

  late final Device? Function(String guid) _loadDevice;

  /// 设备握手完成后的回调，触发时 client 已经 ready。
  late final void Function(SecureSocketClient)? _onConnected;

  /// ready 后的业务消息回调，握手消息不会透出到业务层。
  late final void Function(SecureSocketClient client, Map<String, dynamic> data)? _onMessage;

  /// ready 后异常关闭回调，握手失败只完成 waitReady 错误。
  void Function(Exception e, SecureSocketClient client)? _onError;

  /// ready 后正常关闭回调，主动 close 不触发它。
  void Function(SecureSocketClient client)? _onDone;

  /// 底层 stream 是否遇错取消，保持 Socket.listen 的原生语义。
  bool? _cancelOnError;

  /// 中转模式下本机设备 id，用于判断准备消息是否来自自己。
  String? _selfDevId;

  /// 预共享 DH key 对应的加密器，避免每次加解密重复创建。
  Encrypter? _dhEncrypter;

  /// 当前连接的 DH 状态，收到对端公钥后生成共享 AES key。
  late final DiffieHellman _dh;

  /// DH 协商出的 AES key，业务消息只使用这个 key 加密。
  late final String _aesKey;

  /// 业务消息 AES 加解密器，只有 _cryptoReady 后才可用。
  late final Encrypter _encrypter;

  /// 底层数据流订阅，close 时必须取消以释放监听资源。
  StreamSubscription<Uint8List>? _stream;

  /// 发送锁保证加密、分包、flush 顺序一致，避免并发包交错。
  final Lock _sendLock = Lock();

  /// 接收锁保证分包后的消息按顺序解密和推进握手状态机。
  final Lock _receiveLock = Lock();

  /// ready 完成信号；connect/fromSocket 外部只在它完成后拿到可用 client。
  final Completer<SecureSocketClient> _readyCompleter = Completer<SecureSocketClient>();

  /// 强制在线探活的等待器，只接受当前连接收到的 pingResult。
  Completer<bool>? _onlineProbeCompleter;

  /// Socket 生命周期状态，防止握手、ready、关闭路径交叉执行。
  SocketConnectionState _state = SocketConnectionState.connecting;

  /// 幂等关闭 Future，多个 close/onDone/onError 入口共享同一次收口。
  Future<void>? _closingFuture;

  /// 握手阶段超时保护，ready 或关闭后必须取消。
  Timer? _handshakeTimer;

  /// ready 后断线回调是否已经通知过，确保业务层最多收到一次。
  bool _disconnectNotified = false;

  /// 是否曾经进入 ready；未 ready 的候选失败不触发业务断线通知。
  bool _becameReady = false;

  /// 中转模式准备阶段是否完成，完成前收到的是中转控制明文。
  bool _forwardReady = false;

  /// DH/AES 是否已经完成，完成前发送和接收都走明文握手协议。
  bool _cryptoReady = false;

  /// connect 消息是否已经发送，避免双方重复进入设备握手第一步。
  bool _connectSent = false;

  /// pairedStatus 是否已经发送，双方各发送一次后才能 ready。
  bool _pairedStatusSent = false;

  /// 握手得到的远端设备信息，ready 前不能被业务层读取。
  BaseDeviceInfo? _devInfo;

  /// 本地和远端都认为已配对时为 true。
  bool _isPaired = false;

  /// 远端当前版本，pairedStatus 完成后必须有值。
  AppVersion? _version;

  /// 远端最低兼容版本，pairedStatus 完成后必须有值。
  AppVersion? _minVersion;

  int get port => _port;

  int get localPort => _socket.port;

  bool get isReady => _state == SocketConnectionState.ready;

  bool get isForwardMode => _connectionMode == ConnectionMode.forward;

  BaseDeviceInfo get devInfo => _devInfo!;

  bool get isPaired => _isPaired;

  AppVersion get version => _version!;

  AppVersion get minVersion => _minVersion!;

  SecureSocketClient._private(this.ip);

  static SecureSocketClient empty = SecureSocketClient._private('127.0.0.1');

  /// 建立 TCP 连接，并等待 DH、设备信息、双方配对状态都完成后返回。
  static Future<SecureSocketClient> connect({
    required String ip,
    required int port,
    required LocalSocketBaseInfo localBaseInfo,
    required Device? Function(String guid) loadDevice,
    String? sourceAddress,
    ConnectionMode connectionMode = ConnectionMode.direct,
    String? targetDevId,
    String? selfDevId,
    void Function(SecureSocketClient)? onConnected,
    void Function(SecureSocketClient client, Map<String, dynamic> data)? onMessage,
    void Function(Exception e, SecureSocketClient client)? onError,
    void Function(SecureSocketClient client)? onDone,
    bool? cancelOnError,
    CancelToken? cancelToken,
  }) async {
    final socket = await _connectSocket(
      ip: ip,
      port: port,
      sourceAddress: sourceAddress,
      cancelToken: cancelToken,
    );
    if (cancelToken?.isCanceled ?? false) {
      socket.destroy();
      throw SocketException('Socket connection canceled after connected: $ip:$port');
    }
    final client = SecureSocketClient.fromSocket(
      socket: socket,
      loadDevice: loadDevice,
      localBaseInfo: localBaseInfo,
      connectionMode: connectionMode,
      targetDevId: targetDevId,
      selfDevId: selfDevId,
      onConnected: onConnected,
      onMessage: onMessage,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
      isInitiator: true,
    );
    try {
      if (connectionMode == ConnectionMode.direct) {
        await client._sendKey();
      } else {
        await client.send(<String, dynamic>{
          'self': selfDevId,
          'target': targetDevId,
        });
      }
      return await client.waitReady(cancelToken: cancelToken);
    } catch (_) {
      await client.close();
      rethrow;
    }
  }

  /// 包装已建立的 Socket；调用方可继续用 waitReady 等待完整设备握手。
  factory SecureSocketClient.fromSocket({
    required Socket socket,
    required LocalSocketBaseInfo localBaseInfo,
    required Device? Function(String guid) loadDevice,
    ConnectionMode connectionMode = ConnectionMode.direct,
    String? targetDevId,
    String? selfDevId,
    int? serverPort,
    void Function(SecureSocketClient)? onConnected,
    required void Function(SecureSocketClient client, Map<String, dynamic> data)? onMessage,
    void Function(Exception e, SecureSocketClient client)? onError,
    void Function(SecureSocketClient client)? onDone,
    bool? cancelOnError,
    bool isInitiator = false,
  }) {
    final isForward = connectionMode == ConnectionMode.forward;
    if (isForward) {
      assert(targetDevId.isNotNullAndEmpty);
      assert(selfDevId.isNotNullAndEmpty);
    }
    final client = SecureSocketClient._private(socket.remoteAddress.address);
    client._socket = socket;
    if (serverPort != null) {
      client._port = serverPort;
    }
    client._loadDevice = loadDevice;
    client._baseInfo = localBaseInfo;
    client._connectionMode = connectionMode;
    client._selfDevId = selfDevId;
    client._onConnected = onConnected;
    client._onMessage = onMessage;
    client._onError = onError;
    client._onDone = onDone;
    client._cancelOnError = cancelOnError;
    client._state = SocketConnectionState.handshaking;
    final cryptoConfig = localBaseInfo.cryptoConfig;
    final dhAesKey = cryptoConfig.dhAesKey;
    if (dhAesKey != null) {
      client._dhEncrypter = CryptoUtil.getEncrypter(dhAesKey);
    }
    client._listen();
    client._startHandshakeTimeout();
    return client;
  }

  /// 等待当前 Socket 完成设备级握手；取消令牌失效时会主动关闭候选连接。
  Future<SecureSocketClient> waitReady({CancelToken? cancelToken}) async {
    Timer? cancelTimer;
    if (cancelToken != null) {
      cancelTimer = Timer.periodic(socketCancelPollInterval, (_) {
        if (cancelToken.isCanceled) {
          unawaited(close());
        }
      });
    }
    try {
      return await _readyCompleter.future.timeout(socketHandshakeTimeout);
    } finally {
      cancelTimer?.cancel();
    }
  }

  static Future<Socket> _connectSocket({
    required String ip,
    required int port,
    String? sourceAddress,
    CancelToken? cancelToken,
  }) async {
    final connectionTask = await Socket.startConnect(
      ip,
      port,
      sourceAddress: sourceAddress,
    );
    Timer? cancelTimer;
    if (cancelToken != null) {
      cancelTimer = Timer.periodic(socketCancelPollInterval, (_) {
        if (cancelToken.isCanceled) {
          connectionTask.cancel();
        }
      });
    }
    try {
      if (cancelToken?.isCanceled ?? false) {
        connectionTask.cancel();
        throw SocketException('Socket connection canceled: $ip:$port');
      }
      return await connectionTask.socket.timeout(
        socketConnectTimeout,
        onTimeout: () {
          connectionTask.cancel();
          throw SocketException('Socket connection timed out: $ip:$port');
        },
      );
    } catch (_) {
      connectionTask.cancel();
      rethrow;
    } finally {
      cancelTimer?.cancel();
    }
  }

  void _startHandshakeTimeout() {
    _handshakeTimer = Timer(socketHandshakeTimeout, () {
      if (_state != SocketConnectionState.handshaking) {
        return;
      }
      unawaited(
        _terminate(
          error: TimeoutException(
            'Socket handshake timed out.',
            socketHandshakeTimeout,
          ),
          notify: true,
        ),
      );
    });
  }

  /// 订阅分包流；所有 EOF、错误和解析失败都统一进入连接收口。
  void _listen() {
    if (_stream != null) {
      throw StateError('SecureSocketClient has already started listening.');
    }
    _stream = _socket
        .transform(DataPacketSplitter())
        .listen(
          (bytes) {
            unawaited(_receiveLock.synchronized(() => _onDataReceive(bytes)));
          },
          onError: (Object error) {
            unawaited(_terminate(error: error, notify: true));
          },
          onDone: () {
            unawaited(_terminate(notify: true));
          },
          cancelOnError: _cancelOnError,
        );
  }

  Future<void> _onDataReceive(Uint8List bytes) async {
    try {
      if (isForwardMode && !_forwardReady) {
        await _handleForwardPreparation(bytes);
        return;
      }
      if (!_cryptoReady) {
        await _exchange(utf8.decode(bytes));
        return;
      }
      await _handleEncryptedMessage(bytes);
    } catch (error) {
      await _terminate(error: error, notify: true);
    }
  }

  Future<void> _handleForwardPreparation(Uint8List bytes) async {
    final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    final type = ForwardMsgType.getValue(json['type']);
    logger.debug(tag, 'Forward preparation message: ${type.name}');
    switch (type) {
      case ForwardMsgType.bothConnected:
        await send(<String, dynamic>{'type': ForwardMsgType.bothConnected.name});
        if (json['sender'] != _selfDevId) {
          _forwardReady = true;
        }
        break;
      case ForwardMsgType.forwardReady:
        _forwardReady = true;
        await _sendKey();
        break;
      default:
        break;
    }
  }

  Future<void> _handleEncryptedMessage(Uint8List bytes) async {
    final decrypted = await _decryptPacket(bytes);
    final map = (m2.deserialize(decrypted) as Map<dynamic, dynamic>).cast<String, dynamic>();
    final message = MessageData.fromJson(map);
    if (_state == SocketConnectionState.ready) {
      await _handleReadyMessage(message, map);
      return;
    }
    await _handleDeviceHandshakeMessage(message);
  }

  Future<void> _handleReadyMessage(
    MessageData message,
    Map<String, dynamic> rawMap,
  ) async {
    if (message.key == MsgType.ping && message.data.containsKey('result')) {
      await _sendPingResult();
    } else if (message.key == MsgType.pingResult) {
      _onlineProbeCompleter?.complete(true);
    }
    _onMessage?.call(this, rawMap);
  }

  Future<void> _handleDeviceHandshakeMessage(MessageData message) async {
    switch (message.key) {
      case MsgType.connect:
        await _handleConnectMessage(message);
        break;
      case MsgType.pairedStatus:
        await _handlePairedStatusMessage(message);
        break;
      default:
        throw StateError('Unsupported message before Socket ready: ${message.key.name}');
    }
  }

  Future<void> _handleConnectMessage(MessageData message) async {
    final remoteDev = message.send;
    final localBaseDevInfo = _baseInfo.baseDeviceInfo;
    if (remoteDev.guid == localBaseDevInfo.guid) {
      throw StateError('Cannot connect to self.');
    }

    final localDevice = _loadDevice(remoteDev.guid);
    final localIsPaired = localDevice?.isPaired ?? false;
    if (!_baseInfo.allowDiscover && !localIsPaired) {
      throw StateError('Unpaired device discovery is disabled.');
    }
    _devInfo = remoteDev;
    await _sendPairingState(remoteDev);
  }

  Future<void> _handlePairedStatusMessage(MessageData message) async {
    final remoteDev = message.send;
    _devInfo = remoteDev;
    if (!_pairedStatusSent) {
      await _sendPairingState(remoteDev);
    }
    final localDevice = _loadDevice(remoteDev.guid);
    final localIsPaired = localDevice?.isPaired ?? false;
    final remoteIsPaired = message.data['isPaired'] == true;
    _isPaired = localIsPaired && remoteIsPaired;
    _minVersion = _parseVersion(
      message.data,
      nameKey: 'minVersionName',
      codeKey: 'minVersionCode',
      fallback: _baseInfo.minVersion,
    );
    _version = _parseVersion(
      message.data,
      nameKey: 'versionName',
      codeKey: 'versionCode',
      fallback: _baseInfo.localVersion,
    );
    _markReady();
  }

  AppVersion _parseVersion(
    Map<String, dynamic> data, {
    required String nameKey,
    required String codeKey,
    required AppVersion fallback,
  }) {
    final name = data[nameKey]?.toString();
    final code = data[codeKey]?.toString();
    if (name == null || code == null) {
      return fallback;
    }
    return AppVersion(name, code);
  }

  Future<void> _sendConnectMessage() async {
    if (_connectSent) {
      return;
    }
    _connectSent = true;
    await send(
      MessageData(
        send: _baseInfo.baseDeviceInfo,
        key: MsgType.connect,
        data: const <String, dynamic>{},
      ).toJson(),
    );
  }

  Future<void> _sendPairingState(BaseDeviceInfo remoteDev) async {
    if (_pairedStatusSent) {
      return;
    }
    _pairedStatusSent = true;
    final localDevice = _loadDevice(remoteDev.guid);
    final localIsPaired = localDevice?.isPaired ?? false;
    await send(
      MessageData(
        send: _baseInfo.baseDeviceInfo,
        key: MsgType.pairedStatus,
        data: <String, dynamic>{
          'isPaired': localIsPaired,
          'minVersionName': _baseInfo.minVersion.name,
          'minVersionCode': _baseInfo.minVersion.code,
          'versionName': _baseInfo.localVersion.name,
          'versionCode': _baseInfo.localVersion.code,
        },
      ).toJson(),
    );
  }

  Future<void> _sendPingResult() async {
    await send(
      MessageData(
        send: _baseInfo.baseDeviceInfo,
        key: MsgType.pingResult,
        data: const <String, dynamic>{},
      ).toJson(),
    );
  }

  String _dhEncrypt(String content) {
    final cryptoConfig = _baseInfo.cryptoConfig;
    final dhAesKey = cryptoConfig.dhAesKey;
    if (dhAesKey.isNullOrEmpty) {
      return content;
    }
    return CryptoUtil.encryptAES(key: dhAesKey!, input: content, encrypter: _dhEncrypter);
  }

  String _dhDecrypt(String encrypted) {
    final cryptoConfig = _baseInfo.cryptoConfig;
    final dhAesKey = cryptoConfig.dhAesKey;
    if (dhAesKey.isNullOrEmpty) {
      return encrypted;
    }
    return CryptoUtil.decryptAES(key: dhAesKey!, encoded: encrypted, encrypter: _dhEncrypter);
  }

  /// 兼容旧调用方的 DH 第一步发送入口。
  void sendKey() {
    unawaited(_sendKey());
  }

  Future<void> _sendKey() async {
    if (_cryptoReady) {
      throw StateError('Socket handshake has already completed.');
    }
    final cryptoConfig = _baseInfo.cryptoConfig;
    final generator = BigInt.from(65537);
    final prime1 = cryptoConfig.prime1;
    final prime2 = cryptoConfig.prime2;
    _dh = DiffieHellman(prime1, generator, prime2);
    await send(<String, dynamic>{
      'seq': 1,
      'prime': _dhEncrypt(prime1.toString()),
      'g': _dhEncrypt(generator.toString()),
      'key': _dhEncrypt(_dh.publicKey.toString()),
      'port': _baseInfo.localListenPort,
    });
  }

  Future<void> _exchange(String message) async {
    final data = jsonDecode(message) as Map<String, dynamic>;
    final seq = data['seq'];
    if (seq == 1) {
      final generator = BigInt.parse(_dhDecrypt(data['g']));
      final prime = BigInt.parse(_dhDecrypt(data['prime']));
      _dh = DiffieHellman(prime, generator, _baseInfo.cryptoConfig.prime2);
      final otherPublicKey = BigInt.parse(_dhDecrypt(data['key']));
      final sharedKey = _dh.generateSharedSecret(otherPublicKey);
      _aesKey = sharedKey.toString().substring(0, 32);
      _encrypter = CryptoUtil.getEncrypter(_aesKey);
      _port = data['port'];
      await send(<String, dynamic>{
        'seq': 2,
        'key': _dhEncrypt(_dh.publicKey.toString()),
        'port': _baseInfo.localListenPort,
      });
      await _setCryptoReady();
      return;
    }
    if (seq == 2) {
      _port = data['port'];
      final otherPublicKey = BigInt.parse(_dhDecrypt(data['key']));
      final sharedKey = _dh.generateSharedSecret(otherPublicKey);
      _aesKey = sharedKey.toString().substring(0, 32);
      _encrypter = CryptoUtil.getEncrypter(_aesKey);
      await _setCryptoReady();
      return;
    }
    throw FormatException('Unknown DH sequence: $seq');
  }

  Future<void> _setCryptoReady() async {
    if (_cryptoReady) {
      throw StateError('Socket crypto handshake has already completed.');
    }
    _cryptoReady = true;
    await _sendConnectMessage();
  }

  void _markReady() {
    if (_state == SocketConnectionState.ready) {
      return;
    }
    if (_state != SocketConnectionState.handshaking) {
      throw StateError('Socket cannot become ready from state ${_state.name}.');
    }
    _state = SocketConnectionState.ready;
    _becameReady = true;
    _handshakeTimer?.cancel();
    _handshakeTimer = null;
    if (!_readyCompleter.isCompleted) {
      _readyCompleter.complete(this);
    }
    _onConnected?.call(this);
  }

  Future<Uint8List> _decryptPacket(Uint8List bytes) async {
    if (bytes.length > useComputeThreshold) {
      return compute(
        (List<dynamic> params) {
          return CryptoUtil.decryptAESAsBytes(
            key: params[0],
            encoded: params[2],
            encrypter: params[1],
          );
        },
        <dynamic>[_aesKey, _encrypter, bytes],
      );
    }
    return CryptoUtil.decryptAESAsBytes(
      key: _aesKey,
      encoded: bytes,
      encrypter: _encrypter,
    );
  }

  /// 串行加密并发送一条完整消息，发送失败会统一关闭当前连接。
  Future<void> send(Map map) async {
    if (_state == SocketConnectionState.closing || _state == SocketConnectionState.closed) {
      throw StateError('Cannot send on a closed Socket.');
    }
    try {
      await _sendLock.synchronized(() async {
        final data = await _genSendData(map);
        final packetCount = (data.length / packetMaxPayloadSize).ceil();
        for (var index = 0; index < packetCount; index++) {
          final start = index * packetMaxPayloadSize;
          final end = (start + packetMaxPayloadSize).clamp(0, data.length);
          final packetData = data.sublist(start, end);
          final header = createPacketHeader(data.length, packetData.length, packetCount, index + 1);
          final packet = Uint8List(header.length + packetData.length);
          packet.setAll(0, header);
          packet.setAll(header.length, packetData);
          _socket.add(packet);
          await _socket.flush();
        }
      });
    } catch (error) {
      await _terminate(error: error, notify: true);
      rethrow;
    }
  }

  Future<Uint8List> _genSendData(Map map) async {
    if (!_cryptoReady) {
      return Uint8List.fromList(utf8.encode(jsonEncode(map)));
    }
    final serialized = m2.serialize(map);
    if (serialized.length > useComputeThreshold) {
      return compute(
        (List<dynamic> params) {
          return CryptoUtil.encryptAESWithBytes(
            key: params[0],
            input: params[2],
            encrypter: params[1],
          );
        },
        <dynamic>[_aesKey, _encrypter, serialized],
      );
    }
    return CryptoUtil.encryptAESWithBytes(
      key: _aesKey,
      input: serialized,
      encrypter: _encrypter,
    );
  }

  /// 发送强制在线探测，并且只接受当前连接收到的 pingResult。
  Future<bool> testOnline({
    Duration timeout = socketOnlineProbeTimeout,
  }) async {
    if (!isReady || _onlineProbeCompleter != null) {
      return false;
    }
    final completer = Completer<bool>();
    _onlineProbeCompleter = completer;
    try {
      await send(
        MessageData(
          send: _baseInfo.baseDeviceInfo,
          key: MsgType.ping,
          data: const <String, dynamic>{'result': null},
        ).toJson(),
      );
      return await completer.future.timeout(timeout, onTimeout: () => false);
    } catch (error, stackTrace) {
      logger.debug(tag, 'Socket online probe failed: $error $stackTrace');
      return false;
    } finally {
      _onlineProbeCompleter = null;
    }
  }

  /// 幂等关闭连接；主动关闭不触发业务断线回调，由上层统一决定是否通知或重连。
  Future<void> close() => _terminate(notify: false);

  Future<void> _terminate({Object? error, required bool notify}) {
    final closingFuture = _closingFuture;
    if (closingFuture != null) {
      return closingFuture;
    }
    final future = _closeAndNotify(error: error, notify: notify);
    _closingFuture = future;
    return future;
  }

  Future<void> _closeAndNotify({Object? error, required bool notify}) async {
    if (_state != SocketConnectionState.closed) {
      _state = SocketConnectionState.closing;
    }
    _handshakeTimer?.cancel();
    _handshakeTimer = null;
    _onlineProbeCompleter?.complete(false);
    _onlineProbeCompleter = null;
    if (!_readyCompleter.isCompleted) {
      if (error != null) {
        _readyCompleter.completeError(error);
      } else {
        _readyCompleter.completeError(const SocketException('Socket closed before ready.'));
      }
    }
    try {
      await _socket.close().timeout(socketGracefulCloseTimeout);
    } catch (_) {
      // 超时或底层异常后仍会 destroy，确保系统资源收口。
    } finally {
      try {
        await _stream?.cancel();
      } catch (_) {}
      _socket.destroy();
      _state = SocketConnectionState.closed;
      if (notify) {
        _notifyDisconnected(error);
      }
    }
  }

  void _notifyDisconnected(Object? error) {
    if (_disconnectNotified || !_becameReady) {
      return;
    }
    _disconnectNotified = true;
    if (error != null) {
      _onError?.call(error is Exception ? error : Exception(error.toString()), this);
    } else {
      _onDone?.call(this);
    }
  }

  /// 创建保持兼容的 10 字节大端包头。
  static Uint8List createPacketHeader(
    int totalPayloadSize,
    int payloadSize,
    int packetSize,
    int seq,
  ) {
    final byteData = ByteData(packetHeaderSize);
    byteData.setUint32(0, totalPayloadSize, Endian.big);
    byteData.setUint16(4, payloadSize, Endian.big);
    byteData.setUint16(6, packetSize, Endian.big);
    byteData.setUint16(8, seq, Endian.big);
    return byteData.buffer.asUint8List();
  }
}
