import 'dart:io';

import 'package:clipshare/shared/utils/log.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkUtil {
  /// 组播 socket 构建日志标签
  static const _multicastTag = 'Multicast';

  /// 获取并过滤系统网卡，统一剔除名称中包含 rmnet_data 的网卡。
  static Future<List<NetworkInterface>> listInterfaces() async {
    return NetworkInterface.list().then((interfaces) => interfaces.where((itf) => !itf.name.contains('rmnet_data')).toList());
  }

  /// 枚举可用网卡（排除 [noDiscoveryIfs]），为每个 IPv4 地址绑定 [port]。
  /// [joinGroup] 为 true 时加入 [multicastGroup] 组播组用于接收广播；
  /// 为 false 时仅用于发送（指定出接口），不加入组播组。
  /// 绑定失败的网卡记日志后跳过。
  static Future<List<RawDatagramSocket>> bindMulticastSockets(
    String multicastGroup,
    int port, {
    required List<String> noDiscoveryIfs,
    bool joinGroup = true,
  }) async {
    const ipv4Type = InternetAddressType.IPv4;
    final interfaces = (await listInterfaces()).where((item) => !noDiscoveryIfs.contains(item.name));
    final sockets = <RawDatagramSocket>[];
    for (final interface in interfaces) {
      final address = interface.addresses.where((item) => item.type == ipv4Type).firstOrNull;
      if (address == null) continue;
      try {
        final socket = await RawDatagramSocket.bind(address, port);
        if (joinGroup) {
          socket.joinMulticast(InternetAddress(multicastGroup), interface);
        }
        sockets.add(socket);
      } catch (error, stackTrace) {
        logger.debug(_multicastTag, 'Failed to bind multicast socket on ${interface.name}: $error $stackTrace');
      }
    }
    return sockets;
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
