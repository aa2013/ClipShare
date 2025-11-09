import 'package:clipshare/app/data/models/dev_info.dart';
import 'package:clipshare/app/data/models/version.dart';
import 'package:clipshare/app/handlers/socket/secure_socket_client.dart';

class DevSocket {
  DevInfo dev;
  SecureSocketClient socket;
  bool isPaired;
  AppVersion? minVersion;
  AppVersion? version;
  DateTime lastPingTime = DateTime.now();

  DevSocket({
    required this.dev,
    required this.socket,
    this.isPaired = false,
    this.minVersion,
    this.version,
  });

  void updatePingTime() {
    lastPingTime = DateTime.now();
  }
}
