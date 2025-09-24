import 'package:clipshare/app/data/enums/transport_protocol.dart';
import 'package:clipshare/app/data/models/dev_info.dart';
import 'package:clipshare/app/data/models/version.dart';

abstract mixin class DevAliveListener {
  //连接成功
  void onConnected(
    DevInfo info,
    AppVersion minVersion,
    AppVersion version,
    TransportProtocol protocol,
  ) {}

  //断开连接
  void onDisconnected(String devId) {}

  //配对成功
  void onPaired(DevInfo dev, int uid, bool result, String? address) {}

  //取消配对
  void onCancelPairing(DevInfo dev) {}

  //忘记设备
  void onForget(DevInfo dev, int uid) {}
}
