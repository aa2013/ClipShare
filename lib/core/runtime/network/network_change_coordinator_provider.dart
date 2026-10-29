import 'package:clipshare/core/runtime/app_state/app_state.dart';
import 'package:clipshare/core/runtime/app_state/app_state_provider.dart';
import 'package:clipshare/core/services/transport/socket/discovery/discovery_provider.dart';
import 'package:clipshare/core/services/transport/socket/forward/forward_server_provider.dart';
import 'package:clipshare/core/services/transport/socket/session/session_provider.dart';
import 'package:clipshare/core/services/transport/storage/storage_provider.dart';
import 'package:clipshare/core/settings/discovery/discovery_settings_provider.dart';
import 'package:clipshare/shared/utils/network_util.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'network_change_coordinator_provider.g.dart';

@Riverpod(keepAlive: true)
class NetworkChangeCoordinator extends _$NetworkChangeCoordinator {
  @override
  void build() {
    // 统一监听运行时网络状态，具体的连接恢复和设备发现由协调器处理。
    ref.listen<AppState>(appStateProvider, (previous, current) {
      if (previous == null) {
        return;
      }
      final lastNetwork = previous.currentNetworkType;
      final currentNetwork = current.currentNetworkType;
      if (lastNetwork == currentNetwork) {
        return;
      }
      _onNetworkChanged(lastNetwork, currentNetwork);
    });
  }

  /// 处理网络类型发生变化后的运行时协调逻辑。
  void _onNetworkChanged(ConnectivityResult lastNetwork, ConnectivityResult current) {
    final discoverySettings = ref.read(discoverySettingsProvider).requireValue;
    final keepConnections = NetworkUtil.shouldKeepConnections(
      keepConnectionsOnNetworkSwitch: discoverySettings.keepConnectionsOnNetworkSwitch,
      previous: lastNetwork,
      current: current,
    );
    // 仅在无需处理 WiFi/移动互切和断网恢复时保留现有连接，避免无意义的主动断开重连。
    if (keepConnections) {
      return;
    }
    final discovery = ref.read(discoveryProvider.notifier);
    final forward = ref.read(forwardServerProvider.notifier);
    final session = ref.read(sessionProvider.notifier);
    final storageService = ref.read(storageProvider.notifier);
    //网络变化前的状态，非无网络状态,断开中转服务连接
    if (lastNetwork != ConnectivityResult.none) {
      session.disconnectAllConnections();
      forward.disconnectForwardServer();
      storageService.disconnectWs();
    }
    //网络变化后的处理，重新连接/设备发现
    if (current != ConnectivityResult.none) {
      storageService.reconnectWs();
      storageService.uploadSyncFailedData();
      discovery.restartDiscoveryDevices();
    }
  }
}
