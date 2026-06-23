import 'dart:io';

class NetworkInterfaceFilterUtil {

  /// 获取并过滤系统网卡，统一剔除名称中包含 rmnet_data 的网卡。
  static Future<List<NetworkInterface>> listInterfaces() async {
    return NetworkInterface.list().then((interfaces) => interfaces.where((itf) => !itf.name.contains('rmnet_data')).toList());
  }
}
