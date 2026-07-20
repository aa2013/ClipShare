import 'dart:async';

import 'package:clipshare/app/handlers/socket/secure_socket_client.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:clipshare/app/utils/parallerl_task.dart';

typedef DeviceConnectionProcessor = Future<bool> Function(DeviceConnectionRequest request);
typedef DeviceSocketConnector = Future<SecureSocketClient> Function(CancelToken token);

/// 描述一次设备连接候选，最终 Future 只表达调用结束后设备是否可用。
class DeviceConnectionRequest {
  /// 串行 worker 的 key；已知设备用 devId，未知扫描候选用 address key。
  final String workerKey;

  /// 期望连接到的设备 id；未知扫描候选在握手前可能为空。
  final String? expectedDevId;

  /// 日志描述，用于定位直连、中转、广播或扫描来源。
  final String description;

  /// 请求取消令牌；取消后不能继续登记候选 Socket。
  final CancelToken token;

  /// 真正创建 SecureSocketClient 的函数，返回时必须已经完成设备握手。
  final DeviceSocketConnector connect;

  /// 请求完成信号，worker 会保证只完成一次。
  final Completer<bool> _completer = Completer<bool>();

  DeviceConnectionRequest({
    required this.workerKey,
    required this.description,
    required this.token,
    required this.connect,
    this.expectedDevId,
  });

  /// 外部等待的结果；true 表示目标设备最终在线可用。
  Future<bool> get future => _completer.future;

  /// 幂等完成请求，避免关闭和异常路径重复 complete。
  void complete(bool value) {
    if (!_completer.isCompleted) {
      _completer.complete(value);
    }
  }
}

/// 全局连接入口：用 await for 分发请求，每个设备 worker 再串行处理。
class DeviceConnectionQueue {
  static const String tag = 'DeviceConnectionQueue';

  /// worker 空闲后的默认保留时间，避免刚销毁又入队导致边界复杂。
  static const Duration defaultIdleTtl = Duration(seconds: 15);

  /// 连接请求入口流，只负责分发，不直接建立 Socket。
  final StreamController<DeviceConnectionRequest> _input = StreamController<DeviceConnectionRequest>();

  /// 当前存活的设备 worker，key 与请求 workerKey 一致。
  final Map<String, _DeviceConnectionWorker> _workers = {};

  /// 真正处理单个请求的回调，由 SocketService 注入以复用业务上下文。
  final DeviceConnectionProcessor _processor;

  /// worker 空闲后延迟释放的时间，测试可传更短值。
  final Duration _idleTtl;

  /// 路由循环 Future，用于 close 时等待入口流自然收口。
  Future<void>? _routeFuture;

  /// 队列关闭后不再接收新请求。
  bool _closed = false;

  DeviceConnectionQueue({
    required DeviceConnectionProcessor processor,
    Duration idleTtl = defaultIdleTtl,
  })  : _processor = processor,
        _idleTtl = idleTtl;

  /// 提交连接请求；同一 workerKey 的请求会按提交顺序串行完成。
  Future<bool> enqueue(DeviceConnectionRequest request) {
    if (_closed || request.token.isCanceled) {
      request.complete(false);
      return request.future;
    }
    _ensureStarted();
    _input.add(request);
    return request.future;
  }

  /// 关闭入口流和所有 worker；已入队请求会先自然完成。
  Future<void> close() async {
    if (_closed) {
      return _routeFuture ?? Future<void>.value();
    }
    _closed = true;
    final routeFuture = _routeFuture;
    if (routeFuture == null) {
      // 没有任何请求进入路由循环时，StreamController.close 的 done Future 可能没有监听者完成。
      unawaited(_input.close());
      return;
    }
    await _input.close();
    await routeFuture;
  }

  void _ensureStarted() {
    _routeFuture ??= _routeLoop();
  }

  Future<void> _routeLoop() async {
    try {
      await for (final request in _input.stream) {
        if (request.token.isCanceled) {
          request.complete(false);
          continue;
        }
        final worker = _workerFor(request.workerKey);
        worker.enqueue(request);
      }
    } finally {
      final workers = _workers.values.toList(growable: false);
      _workers.clear();
      for (final worker in workers) {
        await worker.close();
      }
    }
  }

  _DeviceConnectionWorker _workerFor(String key) {
    final current = _workers[key];
    if (current != null && current.accepting) {
      return current;
    }
    final worker = _DeviceConnectionWorker(
      key: key,
      idleTtl: _idleTtl,
      processor: _processor,
      onIdleClosed: (closedWorker) {
        if (identical(_workers[key], closedWorker)) {
          _workers.remove(key);
        }
      },
    );
    _workers[key] = worker;
    worker.start();
    return worker;
  }
}

/// 单设备连接 worker；内部使用 await for 串行消费该设备的请求流。
class _DeviceConnectionWorker {
  /// worker 对应的设备或地址 key，仅用于日志和 identity 移除。
  final String key;

  /// 空闲后保留的 TTL，期间有新请求会取消销毁。
  final Duration idleTtl;

  /// 单请求处理器，由外层 SocketService 提供。
  final DeviceConnectionProcessor processor;

  /// worker 真正关闭时回调 router，router 会做 identity 校验后移除。
  final void Function(_DeviceConnectionWorker worker) onIdleClosed;

  /// 该 worker 的私有请求流，保证同 key 请求逐个处理。
  final StreamController<DeviceConnectionRequest> _queue = StreamController<DeviceConnectionRequest>();

  /// 空闲销毁计时器；新请求入队时必须取消。
  Timer? _idleTimer;

  /// 已入队但尚未 finally 收口的请求数，用于判定是否真的空闲。
  int _pendingCount = 0;

  /// 防止重复启动 await for 循环。
  bool _started = false;

  /// close 已开始后不再接受新请求。
  bool _closing = false;

  /// await for 循环完全退出后置为 true。
  bool _closed = false;

  /// run 循环 Future，close 需要等待它完成。
  Future<void>? _runFuture;

  bool get accepting => !_closing && !_closed;

  _DeviceConnectionWorker({
    required this.key,
    required this.idleTtl,
    required this.processor,
    required this.onIdleClosed,
  });

  /// 启动该 worker 的串行消费循环。
  void start() {
    if (_started) {
      return;
    }
    _started = true;
    _runFuture = _run();
  }

  /// 入队一个请求；若 worker 已关闭，请求会直接失败并由 router 创建新 worker。
  void enqueue(DeviceConnectionRequest request) {
    if (!accepting) {
      request.complete(false);
      return;
    }
    _pendingCount++;
    _idleTimer?.cancel();
    _idleTimer = null;
    _queue.add(request);
  }

  Future<void> _run() async {
    try {
      await for (final request in _queue.stream) {
        var success = false;
        try {
          if (!request.token.isCanceled) {
            success = await processor(request);
          }
        } catch (error, stackTrace) {
          logger.error(
            DeviceConnectionQueue.tag,
            'Device connection request failed. key=$key, request=${request.description}, error=$error',
            stackTrace,
          );
        } finally {
          request.complete(success);
          _pendingCount--;
          if (_pendingCount == 0) {
            _scheduleIdleClose();
          }
        }
      }
    } finally {
      _closed = true;
      onIdleClosed(this);
    }
  }

  void _scheduleIdleClose() {
    if (_closing || _closed) {
      return;
    }
    _idleTimer?.cancel();
    _idleTimer = Timer(idleTtl, () {
      if (_pendingCount != 0 || _closing || _closed) {
        return;
      }
      unawaited(close());
    });
  }

  /// 关闭该 worker；已进入流的请求会先处理完，之后再释放 worker。
  Future<void> close() async {
    if (_closing) {
      return _runFuture ?? Future<void>.value();
    }
    _closing = true;
    _idleTimer?.cancel();
    _idleTimer = null;
    await _queue.close();
    await (_runFuture ?? Future<void>.value());
  }
}
