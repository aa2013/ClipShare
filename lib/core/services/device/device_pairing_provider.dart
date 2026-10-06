import 'package:clipshare/core/constants/app_constants.dart';
import 'package:clipshare/shared/extensions/number_extension.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'device_pairing_provider.g.dart';

class DevicePairingCode {
  final String code;
  final DateTime time = DateTime.now();

  DevicePairingCode(this.code);
}

@Riverpod(keepAlive: true)
class DevicePairingCodeNotifier extends _$DevicePairingCodeNotifier {
  final Map<String, DevicePairingCode> _pairingCodes = {};

  static const tag = 'DevicePairingCodeNotifier';

  @override
  void build() {}

  bool verify(String devId, String code) {
    bool hasKey = _pairingCodes.keys.contains(devId);
    //没有配对码记录，配对失败
    if (!hasKey) return false;
    DevicePairingCode pairCode = _pairingCodes[devId]!;
    var duration = pairingLimit.s;
    //配对超时
    if (DateTime.now().isAfter(pairCode.time.add(duration))) {
      logger.debug(tag, '$devId pairing timeout');
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

  void addCode(String devId, String code) {
    _pairingCodes[devId] = DevicePairingCode(code);
  }

  void removeCode(String devId) {
    _pairingCodes.removeWhere((k, v) => k == devId);
  }
}
