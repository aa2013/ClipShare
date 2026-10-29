import 'dart:async';

import 'package:flutter/foundation.dart';

typedef FutureFunction = Future Function();

/// 取消回调，允许同步收尾，也可以返回 Future 表示异步清理。
typedef CancelCallback = FutureOr<void> Function();

/// 取消令牌源，用于通知尚未开始的任务停止调度。
/// 需要在取消时执行清理逻辑的一方通过 [CancelToken.register] 注册回调。
class CancelTokenSource {
  final CancelToken token = CancelToken();

  /// 重复取消保持幂等，便于多个生命周期入口共同收口。
  /// 首次取消会标记令牌并按注册逆序执行回调；异步回调不阻塞取消流程。
  void cancel() {
    token._notifyCanceled();
  }
}

/// 取消令牌：取消只能由 [CancelTokenSource] 触发，使用方读取状态并注册回调。
class CancelToken {
  static final none = CancelToken();
  bool _isCanceled = false;
  final _registrations = <CancelTokenRegistration>[];

  bool get isCanceled => _isCanceled;

  /// 注册取消回调，返回可用于撤销注册的凭据。
  /// 令牌已取消时回调立即执行，返回的凭据已失效。
  CancelTokenRegistration register(CancelCallback callback) {
    if (_isSharedNone) {
      return CancelTokenRegistration._inactive();
    }
    if (isCanceled) {
      final registration = CancelTokenRegistration._(null, callback);
      registration._fire();
      return registration;
    }
    final registration = CancelTokenRegistration._(this, callback);
    _registrations.add(registration);
    _onRegistrationsChanged();
    return registration;
  }

  /// 合并本次请求令牌和外部取消令牌，任一令牌取消都让候选连接失效。
  CancelToken combine(CancelToken? externalToken) {
    if (externalToken == null) {
      return this;
    }
    return CompositeCancelToken(<CancelToken>[this, externalToken]);
  }

  /// 共享的 [none] 令牌永不取消，注册的回调没有触发机会。
  bool get _isSharedNone => identical(this, none);

  /// 标记令牌已取消并按注册逆序触发回调，重复调用只触发一次。
  void _notifyCanceled() {
    if (_isCanceled) {
      return;
    }
    _isCanceled = true;
    final registrations = List<CancelTokenRegistration>.of(_registrations);
    _registrations.clear();
    // 后注册的回调通常包裹更外层的作用域，逆序执行与嵌套清理顺序一致。
    for (final registration in registrations.reversed) {
      registration._fire();
    }
    _onRegistrationsChanged();
  }

  /// 从注册表中移除已撤销的回调。
  void _unregister(CancelTokenRegistration registration) {
    _registrations.remove(registration);
    _onRegistrationsChanged();
  }

  /// 注册集合变化的钩子，组合令牌靠它维护子令牌转发器。
  void _onRegistrationsChanged() {}
}

/// 多来源取消令牌用于连接候选，外部重连取消或本地请求取消任一发生都应立即失效。
/// 注册在组合令牌上的回调只触发一次，注销或取消后自动撤销子令牌转发器。
class CompositeCancelToken extends CancelToken {
  final List<CancelToken> tokens;
  final List<CancelTokenRegistration> _forwarders = <CancelTokenRegistration>[];
  bool _forwarding = false;

  CompositeCancelToken(this.tokens);

  @override
  bool get isCanceled => tokens.any((token) => token.isCanceled);

  @override
  void _onRegistrationsChanged() {
    final shouldForward = _registrations.isNotEmpty && !isCanceled;
    if (shouldForward == _forwarding) {
      return;
    }
    _forwarding = shouldForward;
    if (!shouldForward) {
      _clearForwarders();
      return;
    }
    for (final token in tokens) {
      _forwarders.add(token.register(_notifyCanceled));
    }
  }

  /// 释放子令牌上的转发器，避免子令牌长期持有本组合令牌。
  void _clearForwarders() {
    for (final forwarder in _forwarders) {
      forwarder.dispose();
    }
    _forwarders.clear();
  }
}

/// 一次取消回调注册的凭据，注销后回调不再执行。
/// 已开始执行的异步回调无法被中止，注销只阻止后续触发。
class CancelTokenRegistration {
  final CancelToken? _token;
  final CancelCallback? _callback;
  bool _active;

  CancelTokenRegistration._(this._token, this._callback) : _active = true;

  /// 不会触发回调的空凭据，用于共享令牌与已取消令牌。
  CancelTokenRegistration._inactive()
    : _token = null,
      _callback = null,
      _active = false;

  /// 撤销注册；重复调用无副作用。
  void dispose() {
    if (!_active) {
      return;
    }
    _active = false;
    _token?._unregister(this);
  }

  /// 标记凭据已消费并执行回调，保证同一注册最多触发一次。
  void _fire() {
    if (!_active) {
      return;
    }
    _active = false;
    _invokeCancelCallback(_callback!);
  }
}

/// 触发单个取消回调：同步部分立即执行，返回的 Future 放到后台等待。
void _invokeCancelCallback(CancelCallback callback) {
  unawaited(_runCancelCallback(callback));
}

/// 等待回调结束并收口异常，单个回调失败不影响其他回调。
Future<void> _runCancelCallback(CancelCallback callback) async {
  try {
    await callback();
  } catch (error, stackTrace) {
    debugPrint('CancelToken callback failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

/// 使用固定数量 worker 执行任务，并隔离单个任务的异常。
class ParallelTask {
  final List<FutureFunction> _tasks;
  final Completer<void> _completer = Completer<void>();
  final CancelToken _token;
  final int maxParallelCnt;
  bool _running = false;
  bool _stopped = false;
  int _nextTaskIndex = 0;

  bool get isCompleted => _completer.isCompleted;

  ParallelTask({
    required List<FutureFunction> tasks,
    this.maxParallelCnt = 10,
    CancelToken? token,
  }) : assert(maxParallelCnt > 0),
       _tasks = tasks,
       _token = token ?? CancelToken.none;

  /// 启动 worker；单个任务失败不会中断其他任务。
  Future<void> run() async {
    if (_running || _completer.isCompleted) {
      return _completer.future;
    }
    _running = true;
    if (_tasks.isEmpty || _stopped || _token.isCanceled) {
      _complete();
      return _completer.future;
    }

    final workerCount = _tasks.length < maxParallelCnt ? _tasks.length : maxParallelCnt;
    try {
      await Future.wait(List<Future<void>>.generate(workerCount, (_) => _runWorker()));
    } finally {
      _complete();
    }
    return _completer.future;
  }

  /// 停止派发新任务；已经启动的任务仍会自然收口。
  Future<void> stop() async {
    _stopped = true;
    if (!_running) {
      _complete();
    }
    await _completer.future;
  }

  /// 单个 worker 顺序领取任务，领取动作在同步区间内完成。
  Future<void> _runWorker() async {
    while (!_stopped && !_token.isCanceled) {
      if (_nextTaskIndex >= _tasks.length) {
        return;
      }
      final task = _tasks[_nextTaskIndex++];
      try {
        await task();
      } catch (error, stackTrace) {
        debugPrint('ParallelTask task failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    }
  }

  /// 只完成一次运行 Future。
  void _complete() {
    if (!_completer.isCompleted) {
      _completer.complete();
    }
  }
}
