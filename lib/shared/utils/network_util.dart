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

  /// 枚举可用网卡（排除 [noDiscoveryIfs]），构建组播收发 socket。
  /// [joinGroup] 为 true 时构建接收 socket：绑定通配地址，并在每张网卡上加入 [multicastGroup] 组播组；
  /// 为 false 时构建发送 socket：为每张网卡的 IPv4 地址绑定 [port]，用于指定出接口发送。
  /// 接收端必须绑定通配地址：Linux/Android 上绑定具体网卡地址的 socket 收不到目的地址为组播组的报文，
  /// 出接口由 [joinMulticast] 的网卡参数决定。
  static Future<List<RawDatagramSocket>> bindMulticastSockets(
    String multicastGroup,
    int port, {
    required List<String> noDiscoveryIfs,
    bool joinGroup = true,
  }) async {
    final interfaces = (await listInterfaces()).where((item) => !noDiscoveryIfs.contains(item.name)).toList();
    if (joinGroup) {
      return _bindMulticastReceiver(multicastGroup, port, interfaces);
    }
    return _bindMulticastSenders(port, interfaces);
  }

  /// 绑定一个通配地址的组播接收 socket，并在每张有 IPv4 地址的网卡上加入组播组
  static Future<List<RawDatagramSocket>> _bindMulticastReceiver(
    String multicastGroup,
    int port,
    List<NetworkInterface> interfaces,
  ) async {
    const ipv4Type = InternetAddressType.IPv4;
    final sockets = <RawDatagramSocket>[];
    final RawDatagramSocket socket;
    try {
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, port);
      // 关闭本机组播回环。
      socket.multicastLoopback = false;
    } catch (error, stackTrace) {
      logger.debug(_multicastTag, 'Failed to bind multicast receiver on port $port: $error $stackTrace');
      return sockets;
    }
    for (final interface in interfaces) {
      final hasIpv4 = interface.addresses.any((item) => item.type == ipv4Type);
      if (!hasIpv4) {
        continue;
      }
      try {
        socket.joinMulticast(InternetAddress(multicastGroup), interface);
      } catch (error, stackTrace) {
        logger.debug(_multicastTag, 'Failed to join multicast group on ${interface.name}: $error $stackTrace');
      }
    }
    sockets.add(socket);
    return sockets;
  }

  /// 为每张网卡的 IPv4 地址绑定一个发送 socket，用于指定组播出接口。
  static Future<List<RawDatagramSocket>> _bindMulticastSenders(int port, List<NetworkInterface> interfaces) async {
    const ipv4Type = InternetAddressType.IPv4;
    final sockets = <RawDatagramSocket>[];
    for (final interface in interfaces) {
      final address = interface.addresses.where((item) => item.type == ipv4Type).firstOrNull;
      if (address == null) {
        continue;
      }
      try {
        final socket = await RawDatagramSocket.bind(address, port);
        // 在发送端关闭本机组播回环。
        socket.multicastLoopback = false;
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
