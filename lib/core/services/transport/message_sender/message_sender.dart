import 'package:clipshare/core/services/device/local_device_info.dart';
import 'package:clipshare/core/services/transport/enums/msg_type.dart';

abstract class MessageSender {
  Future<void> sendData(
    BaseDeviceInfo device,
    MsgType key,
    Map<String, dynamic> data, [
    bool onlyPaired = true,
  ]);
}
