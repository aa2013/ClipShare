import 'dart:convert';

import 'package:clipshare/shared/enums/history_content_type.dart';
import 'package:clipshare/shared/enums/rule/white_black_mode.dart';
import 'package:clipshare/shared/extensions/string_extension.dart';

import 'rule_apply_result.dart';
import 'rule_exec_params.dart';

class RuleRegexContent {
  WhiteBlackMode mode;
  String mainRegex;
  bool allowExtractData;
  String extractRegex;
  bool allowAddTag;
  Set<String> tags;
  bool preventSync;
  bool isFinal;

  RuleRegexContent({
    required this.mainRegex,
    required this.allowExtractData,
    required this.extractRegex,
    required this.allowAddTag,
    required this.tags,
    required this.preventSync,
    required this.isFinal,
    required this.mode,
  });

  factory RuleRegexContent.fromJson(Map<String, dynamic> json) {
    return RuleRegexContent(
      mode: WhiteBlackMode.values.byName(json['mode'] as String),
      mainRegex: json['mainRegex'] as String,
      allowExtractData: json['allowExtractData'] as bool,
      extractRegex: json['extractRegex'] as String,
      allowAddTag: json['allowAddTag'] as bool,
      tags: (json['tags'] as List<dynamic>).map((e) => e as String).toSet(),
      preventSync: json['preventSync'] as bool,
      isFinal: json['isFinal'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mode': mode.name,
      'mainRegex': mainRegex,
      'allowExtractData': allowExtractData,
      'extractRegex': extractRegex,
      'allowAddTag': allowAddTag,
      'tags': tags.toList()..sort(),
      'preventSync': preventSync,
      'isFinal': isFinal,
    };
  }

  RuleApplyResult apply(RuleExecParams params) {
    final content = params.content;
    final contentMatched = content.matchRegExp(mainRegex, multiLines: true, dotAll: true);
    final title = params.title;
    final isNotification = params.type == HistoryContentType.notification;
    final titleMatched = isNotification && title.isNotNullAndEmpty
        ? title!.matchRegExp(mainRegex, multiLines: true, dotAll: true)
        : false;
    final matched = contentMatched || titleMatched;
    final isWhiteMode = mode == WhiteBlackMode.white;
    if (mode != WhiteBlackMode.defaultMode) {
      //白名单模式，未命中则丢弃
      if (isWhiteMode) {
        if (!matched) {
          return params.toApplyResult(drop: true, isFinal: isFinal);
        }
      } else {
        //黑名单模式，命中则丢弃
        if (matched) {
          return params.toApplyResult(drop: true, isFinal: isFinal);
        }
      }
    }
    //默认模式，根据规则判断
    String? extracted;
    if (matched && extractRegex.isNotNullAndEmpty && allowExtractData) {
      extracted = content.firstRegMatch(extractRegex, multiLines: true, dotAll: true);
    }

    return RuleApplyResult(
      title: params.title,
      content: params.content,
      tags: matched && allowAddTag ? tags : {},
      isSyncDisabled: matched ? preventSync : false,
      isFinalRule: isFinal,
      extractedContent: extracted,
    );
  }

  @override
  String toString() {
    return jsonEncode(this);
  }
}
