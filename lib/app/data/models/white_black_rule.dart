import 'dart:convert';

import 'package:clipshare/app/data/enums/history_content_type.dart';
import 'package:clipshare/app/utils/extensions/string_extension.dart';
import 'package:clipshare_clipboard_listener/models/clipboard_source.dart';

class FilterRuleMatchResult {
  final bool matched;
  final FilterRule? rule;
  static const notMatched = FilterRuleMatchResult._private(matched: false, rule: null);

  const FilterRuleMatchResult._private({required this.matched, required this.rule});

  factory FilterRuleMatchResult.matched(FilterRule rule) {
    return FilterRuleMatchResult._private(matched: true, rule: rule);
  }
}

class FilterRule {
  final String content;
  final Set<String> appIds;
  final bool needSync;
  final bool enable;
  final bool ignoreCase;

  bool get isAllApp => appIds.isEmpty;

  bool get isAllContent => content.isEmpty;

  FilterRule({
    required this.content,
    required this.appIds,
    required this.needSync,
    required this.enable,
    this.ignoreCase = false,
  });

  factory FilterRule.fromJson(Map<String, dynamic> map) {
    return FilterRule(
      content: map["content"],
      appIds: Set<String>.from(map["appIds"] ?? []),
      needSync: map["needSync"],
      enable: map["enable"],
      ignoreCase: map["ignoreCase"] ?? false,
    );
  }

  FilterRule copyWith({
    String? content,
    Set<String>? appIds,
    bool? needSync,
    bool? enable,
    bool? ignoreCase,
  }) {
    return FilterRule(
      content: content ?? this.content,
      appIds: appIds ?? this.appIds,
      needSync: needSync ?? this.needSync,
      enable: enable ?? this.enable,
      ignoreCase: ignoreCase ?? this.ignoreCase,
    );
  }

  ///判断是否命中
  bool matched(HistoryContentType type, String content, ClipboardSource? source) {
    // 检查内容匹配
    final contentMatched = isAllContent || content.matchRegExp(this.content, ignoreCase == false);

    // 检查应用匹配
    final appMatched = isAllApp || (source != null && appIds.contains(source.id));

    // 如果内容和应用都匹配，则命中规则
    if (contentMatched && appMatched) {
      return true;
    }
    return false;
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }

  Map<String, dynamic> toJson() {
    return {
      "content": content,
      "appIds": appIds.toList(),
      "needSync": needSync,
      "enable": enable,
      "ignoreCase": ignoreCase,
    };
  }
}
