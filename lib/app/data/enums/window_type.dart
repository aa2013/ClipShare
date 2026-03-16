import 'package:clipshare/app/utils/log.dart';

enum WindowType {
  history,
  fileSender,
  unknown;

  static WindowType parse(String value) {
    return WindowType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () {
        Log.debug("WindowType", "key '$value' unknown");
        throw Exception("Unknown WindowType value: $value");
      },
    );
  }
}
