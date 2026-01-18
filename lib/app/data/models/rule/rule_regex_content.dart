import 'dart:convert';

import 'package:clipshare/app/data/enums/white_black_mode.dart';

class RuleRegexContent {
  WhiteBlackMode? mode;
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
    this.mode,
  });

  factory RuleRegexContent.fromJson(Map<String, dynamic> json) {
    return RuleRegexContent(
      mode: json['mode'] != null ? WhiteBlackMode.values.byName(json['mode'] as String) : null,
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
      'mode': mode?.name,
      'mainRegex': mainRegex,
      'allowExtractData': allowExtractData,
      'extractRegex': extractRegex,
      'allowAddTag': allowAddTag,
      'tags': tags.toList(),
      'preventSync': preventSync,
      'isFinal': isFinal,
    };
  }

  @override
  String toString() {
    return jsonEncode(this);
  }
}
