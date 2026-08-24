import 'package:clipshare/core/database/app_database.dart';

class DevicePairingConfirmResult {
  final bool accepted;
  final bool isPaired;
  final bool changed;
  final Device? device;

  const DevicePairingConfirmResult({
    required this.accepted,
    required this.isPaired,
    required this.changed,
    this.device,
  });
}

