import 'package:clipshare/app/utils/log.dart';

enum RuleScriptLanguage {
  lua,
  unknown;

  static RuleScriptLanguage getValue(String name) =>
      RuleScriptLanguage.values.firstWhere(
        (e) => e.name == name,
        orElse: () {
          Log.debug("RuleScriptLanguage", "key '$name' unknown");
          return RuleScriptLanguage.unknown;
        },
      );
}
