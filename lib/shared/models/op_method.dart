
import 'package:clipshare/shared/utils/log.dart';

enum OpMethod {
  add,
  delete,
  update,
  unknown;

  static OpMethod getValue(String name) => OpMethod.values.firstWhere(
        (e) => e.name == name,
        orElse: () {
          logger.debug('OpMethod', "key '$name' unknown");
          return OpMethod.unknown;
        },
      );
}
