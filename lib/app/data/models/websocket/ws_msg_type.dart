import 'package:clipshare/app/utils/log.dart';

enum WsMsgType {
  change,
  online,
  offline,
  syncFile,
  ping,
  appInfo,
  unknown;

  static WsMsgType getValue(String name) => WsMsgType.values.firstWhere(
    (e) => e.name == name,
    orElse: () {
      Log.debug("WsMsgType", "key '$name' unknown");
      return WsMsgType.unknown;
    },
  );
}
