import 'dart:async';
import 'dart:convert';

import 'package:clipshare/app/data/models/websocket/ws_msg_data.dart';
import 'package:clipshare/app/data/models/websocket/ws_msg_type.dart';
import 'package:clipshare/app/modules/settings_module/pages/settings_section_view_base.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// 存储中转 WebSocket 连接状态。
enum StorageWsStatus {
  connecting,
  connected,
  disconnected,
}

/// 用于创建真实 WebSocket 连接，测试中可替换成带控制能力的包装器。
typedef StorageWsConnectFactory = WebSocketChannel Function(Uri uri);

/// 负责存储中转 WebSocket 的连接、重连、状态和收发消息。
class StorageWsService {
  static const tag = 'StorageWsService';

  final Uri Function() _connectUriBuilder;
  final bool Function() _shouldKeepConnected;
  final Duration _pingInterval;
  final Duration _pingTimeout;
  final Duration _reconnectDelay;
  final StorageWsConnectFactory _connectFactory;
  final FutureOr<void> Function(WsMsgData message)? _onMessage;
  final FutureOr<void> Function()? _onConnected;
  final FutureOr<void> Function()? _onDisconnected;
  final void Function(StorageWsStatus status)? _onStatusChanged;

  final StreamController<StorageWsStatus> _statusController = StreamController<StorageWsStatus>.broadcast();
  final StreamController<WsMsgData> _messageController = StreamController<WsMsgData>.broadcast();

  WebSocketChannel? _channel;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  int? _activeSessionId;
  int _sessionSeed = 0;
  DateTime? _lastServerMessageAt;
  bool _started = false;
  bool _disposed = false;

  StorageWsService({
    required Uri Function() connectUriBuilder,
    required bool Function() shouldKeepConnected,
    Duration pingInterval = const Duration(seconds: 30),
    Duration? pingTimeout,
    Duration reconnectDelay = const Duration(seconds: 5),
    StorageWsConnectFactory connectFactory = WebSocketChannel.connect,
    FutureOr<void> Function(WsMsgData message)? onMessage,
    FutureOr<void> Function()? onConnected,
    FutureOr<void> Function()? onDisconnected,
    void Function(StorageWsStatus status)? onStatusChanged,
  }) : _connectUriBuilder = connectUriBuilder,
       _shouldKeepConnected = shouldKeepConnected,
       _pingInterval = pingInterval,
       _pingTimeout = pingTimeout ?? pingInterval + 5.s,
       _reconnectDelay = reconnectDelay,
       _connectFactory = connectFactory,
       _onMessage = onMessage,
       _onConnected = onConnected,
       _onDisconnected = onDisconnected,
       _onStatusChanged = onStatusChanged;

  bool get running => _started;

  Stream<StorageWsStatus> get statusStream => _statusController.stream;

  Stream<WsMsgData> get messageStream => _messageController.stream;

  /// 开始建立连接，并允许后续自动重连。
  Future<void> connect() async {
    if (_disposed || !_shouldKeepConnected()) {
      return;
    }
    _started = true;
    await _connectInternal(reconnect: false);
  }

  /// 主动断开连接，并关闭自动重连。
  Future<void> disconnect() async {
    if (_disposed) {
      return;
    }
    _started = false;
    _cancelReconnectTimer();
    final channel = _channel;
    final hasActiveSession = _activeSessionId != null;
    _activeSessionId = null;
    _channel = null;
    _stopPingTimer();
    _lastServerMessageAt = null;
    if (channel != null || hasActiveSession) {
      await _notifyDisconnected(channel);
    }
  }

  /// 立即发起一次手动重连。
  Future<void> reconnect() async {
    if (_disposed || !_shouldKeepConnected()) {
      return;
    }
    await disconnect();
    _started = true;
    await _connectInternal(reconnect: true);
  }

  /// 统一发送消息，避免调用方直接操作底层 sink。
  bool send(WsMsgData message) {
    return _sendEncoded(jsonEncode(message));
  }

  /// 关闭资源，供测试或未来服务释放时使用。
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    await disconnect();
    _disposed = true;
    await _statusController.close();
    await _messageController.close();
  }

  Future<void> _connectInternal({required bool reconnect}) async {
    if (_disposed || !_started || !_shouldKeepConnected()) {
      return;
    }
    if (_channel != null) {
      logger.warn(tag, 'ws already connected');
      return;
    }
    _emitStatus(StorageWsStatus.connecting);
    if (reconnect) {
      logger.info(tag, 'retry websocket connect');
    }
    final sessionId = ++_sessionSeed;
    _activeSessionId = sessionId;
    late final WebSocketChannel channel;
    try {
      final uri = _connectUriBuilder();
      channel = _connectFactory(uri);
      _channel = channel;
      channel.stream.listen(
        (dynamic json) {
          unawaited(_handleRawMessage(sessionId: sessionId, rawJson: json));
        },
        onDone: () {
          unawaited(_handleDisconnected(sessionId: sessionId, reason: 'ws done'));
        },
        onError: (Object err, StackTrace stack) {
          unawaited(
            _handleDisconnected(
              sessionId: sessionId,
              reason: 'ws error',
              error: err,
              stack: stack,
            ),
          );
        },
      );
    } catch (err, stack) {
      await _handleDisconnected(
        sessionId: sessionId,
        reason: 'websocket connect failed',
        error: err,
        stack: stack,
      );
      return;
    }
    try {
      await channel.ready;
      if (!_shouldHandleSession(sessionId)) {
        // 旧会话 ready 晚到时必须主动关闭，避免底层连接泄漏成脱管通道。
        await channel.sink.close();
        return;
      }
      logger.info(tag, 'websocket connected');
      _cancelReconnectTimer();
      _markServerMessageReceived();
      _startPingTimer();
      _emitStatus(StorageWsStatus.connected);
      if (_onConnected != null) {
        await _onConnected();
      }
    } catch (err, stack) {
      await _handleDisconnected(
        sessionId: sessionId,
        reason: 'websocket ready failed',
        error: err,
        stack: stack,
      );
    }
  }

  /// 解析当前会话的服务端消息并刷新活跃时间，旧会话晚到消息会被忽略，避免污染新连接状态。
  Future<void> _handleRawMessage({
    required int sessionId,
    required dynamic rawJson,
  }) async {
    if (!_shouldHandleSession(sessionId)) {
      logger.warn(tag, 'ignore websocket message from inactive session');
      return;
    }
    try {
      final message = WsMsgData.fromJson((jsonDecode(rawJson as String) as Map<dynamic, dynamic>).cast<String, dynamic>());
      _markServerMessageReceived();
      if (message.operation == WsMsgType.ping) {
        logger.debug(tag, 'websocket ping ack received');
        return;
      }
      _messageController.add(message);
      if (_onMessage != null) {
        await _onMessage(message);
      }
    } catch (err, stack) {
      logger.error(tag, '_handleRawMessage $err, $rawJson', stack);
    }
  }

  Future<void> _handleDisconnected({
    required int sessionId,
    required String reason,
    Object? error,
    StackTrace? stack,
  }) async {
    final isActiveSession = _activeSessionId == sessionId;
    final channel = isActiveSession ? _channel : null;
    if (isActiveSession) {
      _activeSessionId = null;
      _channel = null;
      _stopPingTimer();
      _lastServerMessageAt = null;
    }
    if (error == null) {
      logger.debug(tag, reason);
    } else {
      logger.error(tag, '$reason: $error', stack);
    }
    if (!isActiveSession) {
      logger.warn(tag, "WebSocket disconnected, but the session is no longer the active one (likely replaced by a newer connection)");
      return;
    }
    await _notifyDisconnected(channel);
    _scheduleReconnect();
  }

  Future<void> _notifyDisconnected(WebSocketChannel? channel) async {
    _emitStatus(StorageWsStatus.disconnected);
    await _onDisconnected?.call();
    if (channel != null) {
      try {
        await channel.sink.close();
      } catch (err, stack) {
        logger.error(tag, 'close disconnected websocket failed: $err', stack);
      }
    }
  }

  void _scheduleReconnect() {
    if (_disposed || !_started || !_shouldKeepConnected()) {
      return;
    }
    if (_reconnectTimer != null) {
      return;
    }
    _reconnectTimer = Timer(_reconnectDelay, () {
      _reconnectTimer = null;
      if (_disposed || !_started || !_shouldKeepConnected() || _channel != null) {
        return;
      }
      unawaited(_connectInternal(reconnect: true));
    });
  }

  bool _sendEncoded(String payload) {
    final channel = _channel;
    final sessionId = _activeSessionId;
    if (channel == null || sessionId == null) {
      return false;
    }
    try {
      // sink.add 只代表消息写入本地发送队列，不代表远端服务已经收到；真实断线仍依赖心跳超时兜底。
      channel.sink.add(payload);
      return true;
    } catch (err, stack) {
      // 统一把发送期的底层异常转为断线流程，避免 UI 和真实连接状态漂移。
      unawaited(
        _handleDisconnected(
          sessionId: sessionId,
          reason: 'ws send failed',
          error: err,
          stack: stack,
        ),
      );
      return false;
    }
  }

  /// 启动应用层心跳，定期发送 ping 并检查服务端是否在超时时间内返回任意消息。
  void _startPingTimer() {
    _stopPingTimer();
    _pingTimer = Timer.periodic(_pingInterval, (_) {
      final sessionId = _activeSessionId;
      if (sessionId == null) {
        return;
      }
      send(WsMsgData(WsMsgType.ping, '', ''));
      _disconnectIfHeartbeatTimedOut(sessionId);
    });
  }

  /// 停止心跳定时器，避免旧会话断开后继续发送 ping。
  void _stopPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  void _cancelReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  /// 记录服务端最新响应时间，用于识别极端网络下没有 onDone/onError 的半开连接。
  void _markServerMessageReceived() {
    _lastServerMessageAt = DateTime.now();
  }

  /// 当服务端长期没有任何消息返回时，主动收口当前连接并触发重连。
  void _disconnectIfHeartbeatTimedOut(int sessionId) {
    if (!_shouldHandleSession(sessionId)) {
      return;
    }
    final lastServerMessageAt = _lastServerMessageAt;
    if (lastServerMessageAt == null) {
      _markServerMessageReceived();
      return;
    }
    final elapsed = DateTime.now().difference(lastServerMessageAt);
    if (elapsed <= _pingTimeout) {
      return;
    }
    logger.warn(tag, 'websocket heartbeat timeout. elapsed=${elapsed.inMilliseconds}ms, timeout=${_pingTimeout.inMilliseconds}ms');
    unawaited(_handleDisconnected(sessionId: sessionId, reason: 'websocket heartbeat timeout'));
  }

  bool _shouldHandleSession(int sessionId) {
    return !_disposed && _started && _shouldKeepConnected() && _activeSessionId == sessionId;
  }

  void _emitStatus(StorageWsStatus status) {
    if (_disposed) {
      return;
    }
    _statusController.add(status);
    _onStatusChanged?.call(status);
  }
}
