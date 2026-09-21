import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkUtil {

  /// 获取并过滤系统网卡，统一剔除名称中包含 rmnet_data 的网卡。
  static Future<List<NetworkInterface>> listInterfaces() async {
    return NetworkInterface.list().then((interfaces) => interfaces.where((itf) => !itf.name.contains('rmnet_data')).toList());
  }

  /// 仅在用户开启设置，且不是 WiFi/移动网络互切、也不是无网络与有网络互切时保留连接。
  static bool shouldKeepConnections({
    required bool keepConnectionsOnNetworkSwitch,
    required ConnectivityResult previous,
    required ConnectivityResult current,
  }) {
    if (!keepConnectionsOnNetworkSwitch) {
      return false;
    }
    if (_isWifiMobileSwitch(previous, current)) {
      return false;
    }
    if (_isNoneConnectedSwitch(previous, current)) {
      return false;
    }
    return true;
  }

  /// WiFi 与移动网络之间切换仍保持旧逻辑，因为这会影响中转能力的开关状态。
  static bool _isWifiMobileSwitch(
    ConnectivityResult previous,
    ConnectivityResult current,
  ) {
    return (previous == ConnectivityResult.wifi && current == ConnectivityResult.mobile) || (previous == ConnectivityResult.mobile && current == ConnectivityResult.wifi);
  }

  /// 无网络与任意有网络之间切换仍保持旧逻辑，确保恢复连接和重新发现按现有方式触发。
  static bool _isNoneConnectedSwitch(
    ConnectivityResult previous,
    ConnectivityResult current,
  ) {
    return (previous == ConnectivityResult.none && current != ConnectivityResult.none) || (previous != ConnectivityResult.none && current == ConnectivityResult.none);
  }
}
