import 'package:clipshare/app/utils/log.dart';

enum RuleType {
  tag,
  sms,
  unknown;

  static RuleType getValue(String name) => RuleType.values.firstWhere(
        (e) => e.name == name,
        orElse: () {
          logger.debug("Rule", "key '$name' unknown");
          return RuleType.unknown;
        },
      );
}
