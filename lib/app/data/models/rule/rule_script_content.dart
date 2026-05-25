import 'dart:convert';

import 'package:clipshare/app/data/enums/rule/rule_script_language.dart';
import 'package:clipshare/app/data/models/rule/rule_apply_result.dart';
import 'package:clipshare/app/data/models/rule/rule_exec_params.dart';

class RuleScriptContent {
  RuleScriptLanguage language;
  String content;

  RuleScriptContent({
    required this.language,
    required this.content,
  });

  factory RuleScriptContent.fromJson(Map<String, dynamic> json) {
    return RuleScriptContent(
      language: RuleScriptLanguage.values.byName(
        json['language'] as String,
      ),
      content: json['content'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'language': language.name,
      'content': content,
    };
  }

  @override
  String toString() {
    return jsonEncode(this);
  }
}
