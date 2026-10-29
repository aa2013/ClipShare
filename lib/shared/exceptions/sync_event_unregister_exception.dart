import 'package:clipshare/shared/models/module.dart';

class SyncEventUnregisterException {
  final Module module;

  const SyncEventUnregisterException(this.module);

  @override
  String toString() => 'SyncEventUnregisterException: devId=${module.name}';
}
