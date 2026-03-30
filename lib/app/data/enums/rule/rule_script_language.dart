import 'package:clipshare/app/utils/log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:simple_icons/simple_icons.dart';

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

  IconData get icon {
    switch (this) {
      case RuleScriptLanguage.lua:
        return SimpleIcons.lua;
      case RuleScriptLanguage.unknown:
        return Icons.question_mark_outlined;
    }
  }
}
