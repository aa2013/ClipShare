import 'dart:async';

import 'package:clipshare/core/platform/channels/android/android_channel_provider.dart';
import 'package:clipshare/core/platform/channels/android/events/screen_opened_event.dart';
import 'package:clipshare/core/settings/discovery/discovery_settings.dart';
import 'package:clipshare/core/settings/discovery/discovery_settings_provider.dart';
import 'package:clipshare/shared/extensions/number_extension.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

part 'transport_heartbeat_provider.g.dart';

/// 统一管理传输层心跳生命周期，具体心跳内容由各传输服务自行实现。
@Riverpod(keepAlive: true)
class TransportHeartbeatNotifier extends _$TransportHeartbeatNotifier /*GetxService with ScreenOpenedObserver */ {
  static const tag = 'TransportHeartbeatService';
  static const _screenOffAutoCloseDelay = Duration(minutes: 2);

  final Map<String, TransportHeartbeatTask> _tasks = <String, TransportHeartbeatTask>{};
  final Map<String, Timer> _timers = <String, Timer>{};
  Timer? _screenOffAutoCloseTimer;
  bool _screenOpened = true;
  bool _screenOffAutoClosed = false;

  /// 最近一次已应用的心跳间隔，用于过滤无关的发现配置变更。
  int? _appliedHeartbeatInterval;

  /// 屏幕状态订阅事件流
  StreamSubscription<ScreenEvent>? _screenEventsSubscription;

  bool get screenOpened => _screenOpened;

  bool get screenOffAutoClosed => _screenOffAutoClosed;

  DiscoverySettings get _discoverySettings => ref.read(discoverySettingsProvider).requireValue;

  AndroidChannelNotifier get _androidChannel => ref.read(androidChannelProvider.notifier);

  @override
  void build() {
    _screenEventsSubscription = _androidChannel.screenEvents.listen(_onScreenEvent);

    _appliedHeartbeatInterval = _discoverySettings.heartbeatInterval;
    // 仅心跳间隔变化时重建已注册任务的定时器
    ref.listen(discoverySettingsProvider, (_, next) {
      final settings = next.asData?.value;
      if (settings == null) {
        return;
      }
      _applyHeartbeatInterval(settings);
    });
    ref.onDispose(_dispose);
  }

  void _dispose() {
    _screenEventsSubscription?.cancel();
    stopAll(reason: TransportHeartbeatStopReason.dispose);
    _cancelScreenOffAutoClose();
  }

  /// 注册一个心跳任务；重复注册会覆盖旧任务并停止旧定时器。
  void registerTask(TransportHeartbeatTask task) {
    stop(task.name);
    _tasks[task.name] = task;
  }

  /// 注销指定心跳任务，通常用于服务释放或彻底关闭。
  void unregisterTask(String name) {
    stop(name, reason: TransportHeartbeatStopReason.unregister);
    _tasks.remove(name);
  }

  /// 启动指定心跳任务，首次是否立即执行由调用方决定。
  void start(String name, {bool immediately = true}) {
    final task = _tasks[name];
    if (task == null) {
      logger.warn(tag, 'heartbeat task not found. name=$name');
      return;
    }
    final devSettings = _discoverySettings;
    _timers.remove(name)?.cancel();
    if (!_screenOpened && devSettings.autoCloseConnAfterScreenOff && _screenOffAutoClosed) {
      logger.debug(tag, 'skip heartbeat start because screen auto close already reached. name=$name');
      return;
    }
    if (immediately) {
      unawaited(_runTask(task, trigger: TransportHeartbeatTrigger.start));
    }
    final interval = devSettings.heartbeatInterval;
    if (interval <= 0) {
      logger.debug(tag, 'heartbeat timer disabled by config. name=$name');
      return;
    }
    _scheduleTimer(task, interval);
  }

  /// 按指定间隔为任务创建周期定时器，重复创建会先取消旧定时器。
  void _scheduleTimer(TransportHeartbeatTask task, int interval) {
    _timers.remove(task.name)?.cancel();
    _timers[task.name] = Timer.periodic(interval.s, (_) {
      unawaited(_runTask(task, trigger: TransportHeartbeatTrigger.timer));
    });
  }

  /// 按最新配置重建已注册任务的定时器。
  ///
  /// 仅心跳间隔变化时处理；间隔关闭或任务当前不应运行时仅取消定时器，
  /// 任务保持注册以便后续重新开启，需要运行时复用 [start] 以继承息屏自动断开的保护。
  void _applyHeartbeatInterval(DiscoverySettings settings) {
    final interval = settings.heartbeatInterval;
    if (interval == _appliedHeartbeatInterval) {
      return;
    }
    _appliedHeartbeatInterval = interval;
    for (final task in _tasks.values) {
      final enabled = interval > 0 && task.shouldRun();
      if (!enabled) {
        _timers.remove(task.name)?.cancel();
        continue;
      }
      start(task.name, immediately: false);
    }
  }

  /// 停止指定心跳任务，并按停止原因执行任务自身的停止回调。
  void stop(String name, {TransportHeartbeatStopReason reason = TransportHeartbeatStopReason.manual}) {
    _timers.remove(name)?.cancel();
    final task = _tasks[name];
    if (task != null) {
      // 停止回调允许同步或异步实现，这里统一包成 Future 以便安全地异步收尾。
      unawaited(Future<void>.sync(() => task.onStop?.call(reason)));
    }
  }

  /// 停止所有心跳任务，通常用于息屏自动断开或服务销毁。
  void stopAll({TransportHeartbeatStopReason reason = TransportHeartbeatStopReason.manual}) {
    for (final name in _tasks.keys.toList()) {
      stop(name, reason: reason);
    }
  }

  ///屏幕事件处理
  void _onScreenEvent(ScreenEvent event) {
    if (event is ScreenOpenedEvent) {
      _onScreenOpened();
    } else if (event is ScreenClosedEvent) {
      _onScreenClosed();
    }
  }

  ///屏幕开启事件
  void _onScreenOpened() {
    _screenOpened = true;
    _screenOffAutoClosed = false;
    _cancelScreenOffAutoClose();
    for (final task in _tasks.values) {
      if (task.restartOnScreenOpened) {
        start(task.name, immediately: false);
      }
      unawaited(_runTask(task, trigger: TransportHeartbeatTrigger.screenOpened));
    }
    logger.debug(tag, 'screen opened, restart heartbeat tasks. count=${_tasks.length}');
  }

  ///屏幕关闭事件
  void _onScreenClosed() {
    _screenOpened = false;
    if (!_discoverySettings.autoCloseConnAfterScreenOff) {
      return;
    }
    _screenOffAutoCloseTimer?.cancel();
    logger.debug(tag, 'screen closed, schedule heartbeat auto close after ${_screenOffAutoCloseDelay.inMinutes} minutes');
    WakelockPlus.toggle(enable: true);
    _screenOffAutoCloseTimer = Timer(_screenOffAutoCloseDelay, () {
      WakelockPlus.toggle(enable: false);
      _screenOffAutoCloseTimer = null;
      _screenOffAutoClosed = true;
      logger.debug(tag, 'screen off timeout reached, stop all heartbeat tasks');
      stopAll(reason: TransportHeartbeatStopReason.screenOffAutoClose);
    });
  }

  /// 执行单个心跳任务，并吞掉任务内部异常，避免影响其他心跳。
  Future<void> _runTask(TransportHeartbeatTask task, {required TransportHeartbeatTrigger trigger}) async {
    if (!task.shouldRun()) {
      return;
    }
    try {
      await task.onTick(trigger);
    } catch (err, stack) {
      logger.error(tag, 'heartbeat task failed. name=${task.name}, trigger=${trigger.name}, error=$err', stack);
    }
  }

  /// 取消息屏延迟停止，亮屏时调用以恢复连接和心跳。
  void _cancelScreenOffAutoClose() {
    _screenOffAutoCloseTimer?.cancel();
    _screenOffAutoCloseTimer = null;
    WakelockPlus.toggle(enable: false);
  }
}

/// 心跳任务触发原因，用于日志排查不同生命周期入口。
enum TransportHeartbeatTrigger {
  start,
  timer,
  screenOpened,
  manual,
}

/// 心跳停止原因，用于区分手动停止和息屏到期自动断开等业务语义。
enum TransportHeartbeatStopReason {
  manual,
  screenOffAutoClose,
  unregister,
  dispose,
}

/// 单个传输心跳任务定义，具体发送逻辑由注册方提供。
class TransportHeartbeatTask {
  final String name;
  final bool Function() shouldRun;
  final FutureOr<void> Function(TransportHeartbeatTrigger trigger) onTick;
  final FutureOr<void> Function(TransportHeartbeatStopReason reason)? onStop;
  final bool restartOnScreenOpened;

  /// 创建心跳任务，name 用于唯一标识，onTick 负责执行实际心跳发送。
  const TransportHeartbeatTask({
    required this.name,
    required this.shouldRun,
    required this.onTick,
    this.onStop,
    this.restartOnScreenOpened = true,
  });
}
