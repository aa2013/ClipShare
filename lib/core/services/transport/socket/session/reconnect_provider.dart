import 'package:clipshare/core/constants/network_constants.dart' as net;
import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/database/dao/device_dao.dart';
import 'package:clipshare/core/runtime/app_state/app_state.dart';
import 'package:clipshare/core/runtime/app_state/app_state_provider.dart';
import 'package:clipshare/core/services/device/device_provider.dart';
import 'package:clipshare/core/services/transport/socket/direct/direct_provider.dart';
import 'package:clipshare/core/services/transport/socket/forward/forward_server_provider.dart';
import 'package:clipshare/core/services/transport/socket/session/session_provider.dart';
import 'package:clipshare/shared/extensions/string_extension.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:clipshare/shared/utils/parallerl_task.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reconnect_provider.g.dart';

/// 独立维护每台设备的重连任务和重连窗口。
@Riverpod(keepAlive: true)
class ReconnectNotifier extends _$ReconnectNotifier {
  static const tag = 'ReconnectNotifier';
  final Map<String, CancelTokenSource> _reconnectTokenSources = {};
  final Map<String, Future<void>> _reconnectTasks = {};
  bool _disposed = false;

  DeviceDao get _deviceDao => ref.read(appDbProvider).requireValue.deviceDao;

  DeviceState get _deviceState => ref.read(deviceProvider).requireValue;

  SessionNotifier get _sessionNotifier => ref.read(sessionProvider.notifier);

  AppState get _appState => ref.read(appStateProvider);

  ForwardServerNotifier get _forwardServer => ref.read(forwardServerProvider.notifier);

  DirectNotifier get _directNotifier => ref.read(directProvider.notifier);

  @override
  void build() {
    ref.onDispose(_dispose);
  }

  void _dispose() {
    _disposed = true;
    for (final source in _reconnectTokenSources.values) {
      source.cancel();
    }
  }

  /// 执行一次重连。
  Future<void> reconnectOnce(String guid) => attemptReconnect(guid, true);

  /// 为单个设备启动唯一重连循环。
  Future<void> attemptReconnect(String guid, [bool once = false]) async {
    final running = _reconnectTasks[guid];
    if (running != null) return running;
    final source = CancelTokenSource();
    _reconnectTokenSources[guid]?.cancel();
    _reconnectTokenSources[guid] = source;
    late final Future<void> task;
    task = _runReconnectLoop(guid, source.token, once).whenComplete(() {
      if (identical(_reconnectTasks[guid], task)) {
        _reconnectTasks.remove(guid);
      }
      if (identical(_reconnectTokenSources[guid], source)) {
        _reconnectTokenSources.remove(guid);
      }
    });
    _reconnectTasks[guid] = task;
    return task;
  }

  /// 按内网优先、中转兜底的顺序执行重连。
  Future<void> _runReconnectLoop(String guid, CancelToken token, bool once) async {
    final dev = await _deviceDao.getById(guid);
    if (dev == null) return;
    final deadline = DateTime.now().add(once ? Duration.zero : net.socketReconnectWindow);
    var attempted = false;
    while (!token.isCanceled && !_disposed && (once ? !attempted : DateTime.now().isBefore(deadline))) {
      if (!once) {
        await Future.delayed(net.socketReconnectInterval);
      }
      if (token.isCanceled || _disposed) {
        return;
      }
      final protocol = _deviceState.registry.getProtocol(guid);
      if (protocol != null && !protocol.isSocket) {
        return;
      }
      attempted = true;
      if (await _sessionNotifier.testIsOnline(guid, autoReconnect: false)) {
        return;
      }
      if (_appState.currentNetworkType == ConnectivityResult.none) {
        return;
      }
      try {
        var connected = false;
        final address = dev.internalAddress;
        if (address != null) {
          final parts = address.split(':');
          if (parts.length == 2) {
            connected = await _directNotifier.connect(
              parts[0],
              port: parts[1].toInt(),
              targetDevId: guid,
              cancelToken: token,
            );
          }
        }
        if (!connected && _forwardServer.connected) {
          connected = await _forwardServer.connectDevice(guid, cancelToken: token);
        }
        if (connected) return;
      } catch (error, stackTrace) {
        logger.debug(tag, 'Reconnect attempt failed. device=$guid, error=$error $stackTrace');
      }
    }
  }

  /// 取消指定设备的重连。
  void cancelReconnect(String guid) {
    _reconnectTokenSources.remove(guid)?.cancel();
    _reconnectTasks.remove(guid);
  }
}
