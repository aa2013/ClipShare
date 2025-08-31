import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/extensions/number_extension.dart';
import 'package:clipshare/app/utils/log.dart';

class DevPairCode {
  final String code;
  final DateTime time = DateTime.now();

  DevPairCode(this.code);
}

class DevPairingHandler {
  static final Map<String, DevPairCode> _pairingCodes = {};

  static const String tag = "DevPairingHandler";

  static bool verify(String devId, String code) {
    bool hasKey = _pairingCodes.keys.contains(devId);
    //没有配对码记录，配对失败
    if (!hasKey) return false;
    DevPairCode pairCode = _pairingCodes[devId]!;
    var duration = Constants.pairingLimit.s;
    //配对超时
    if (DateTime.now().isAfter(pairCode.time.add(duration))) {
      Log.debug(tag, "$devId pairing timeout");
      _pairingCodes.removeWhere((k, v) => k == devId);
      return false;
    }
    //配对成功
    if (pairCode.code == code) {
      _pairingCodes.removeWhere((k, v) => k == devId);
      return true;
    }
    return false;
  }

  static void addCode(String devId, String code) {
    _pairingCodes[devId] = DevPairCode(code);
  }

  static void removeCode(String devId) {
    _pairingCodes.removeWhere((k, v) => k == devId);
  }
}
