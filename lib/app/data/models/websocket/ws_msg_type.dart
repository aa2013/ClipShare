import 'package:clipshare/app/utils/log.dart';

enum WsMsgType {
  change,
  online,
  offline,
  syncFile,
  ping,
  appInfo,
  ack,
  unknown;

  static WsMsgType getValue(String name) => WsMsgType.values.firstWhere(
    (e) => e.name == name,
    orElse: () {
      logger.debug("WsMsgType", "key '$name' unknown");
      return WsMsgType.unknown;
    },
  );
}
