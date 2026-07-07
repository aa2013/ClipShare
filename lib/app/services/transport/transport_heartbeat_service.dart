import 'dart:async';

import 'package:clipshare/app/listeners/screen_opened_listener.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/utils/extensions/number_extension.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:get/get.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// 统一管理传输层心跳生命周期，具体心跳内容由各传输服务自行实现。
class TransportHeartbeatService extends GetxService with ScreenOpenedObserver {
  static const tag = 'TransportHeartbeatService';
  static const _screenOffAutoCloseDelay = Duration(minutes: 2);

  final ConfigService appConfig = Get.find<ConfigService>();
  final Map<String, TransportHeartbeatTask> _tasks = <String, TransportHeartbeatTask>{};
  final Map<String, Timer> _timers = <String, Timer>{};
  Timer? _screenOffAutoCloseTimer;
  bool _screenOpened = true;
  bool _screenOffAutoClosed = false;

  bool get screenOpened => _screenOpened;

  bool get screenOffAutoClosed => _screenOffAutoClosed;

  /// 注册亮屏和息屏监听，供主流程初始化时调用。
  TransportHeartbeatService init() {
    ScreenOpenedListener.inst.register(this);
    return this;
  }

  @override
  void onClose() {
    ScreenOpenedListener.inst.remove(this);
    stopAll(reason: TransportHeartbeatStopReason.dispose);
    _cancelScreenOffAutoClose();
    super.onClose();
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
    _timers.remove(name)?.cancel();
    if (!_screenOpened && appConfig.autoCloseConnAfterScreenOff && _screenOffAutoClosed) {
      logger.debug(tag, 'skip heartbeat start because screen auto close already reached. name=$name');
      return;
    }
    if (immediately) {
      unawaited(_runTask(task, trigger: TransportHeartbeatTrigger.start));
    }
    final interval = appConfig.heartbeatInterval;
    if (interval <= 0) {
      logger.debug(tag, 'heartbeat timer disabled by config. name=$name');
      return;
    }
    _timers[name] = Timer.periodic(interval.s, (_) {
      unawaited(_runTask(task, trigger: TransportHeartbeatTrigger.timer));
    });
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

  @override
  void onScreenOpened() {
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

  @override
  void onScreenClosed() {
    _screenOpened = false;
    if (!appConfig.autoCloseConnAfterScreenOff) {
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
