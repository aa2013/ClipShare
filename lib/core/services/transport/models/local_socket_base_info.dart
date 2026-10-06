import 'package:clipshare/core/services/device/local_device_info.dart';
import 'package:clipshare/shared/models/version.dart';

import 'socket_crypto_config.dart';

class LocalSocketBaseInfo {
  final BaseDeviceInfo baseDeviceInfo;
  /// 握手加密配置
  final SocketCryptoConfig cryptoConfig;
  final int localListenPort;
  final AppVersion localVersion;
  final AppVersion minVersion;
  final bool allowDiscover;

  LocalSocketBaseInfo({
    required this.cryptoConfig,
    required this.baseDeviceInfo,
    required this.localListenPort,
    required this.localVersion,
    required this.minVersion,
    required this.allowDiscover,
  });
}
