import 'package:clipshare/app/utils/log.dart';

enum OpMethod {
  add,
  delete,
  update,
  unknown;

  static OpMethod getValue(String name) => OpMethod.values.firstWhere(
        (e) => e.name == name,
        orElse: () {
          Log.debug("OpMethod", "key '$name' unknown");
          return OpMethod.unknown;
        },
      );
}
