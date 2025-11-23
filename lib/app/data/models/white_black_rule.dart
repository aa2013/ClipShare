import 'dart:convert';

import 'package:clipshare/app/data/enums/history_content_type.dart';
import 'package:clipshare/app/utils/extensions/string_extension.dart';
import 'package:clipshare_clipboard_listener/enums.dart';
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
  final Set<HistoryContentType> types;
  final bool needSync;
  final bool enable;
  final bool ignoreCase;

  bool get isAllApp => appIds.isEmpty;

  bool get isAllContent => content.isEmpty;

  static final filterTypes = Set<HistoryContentType>.unmodifiable({HistoryContentType.image, HistoryContentType.text, HistoryContentType.sms, HistoryContentType.notification});

  FilterRule({
    required this.content,
    required this.appIds,
    required this.types,
    required this.needSync,
    required this.enable,
    this.ignoreCase = false,
  });

  factory FilterRule.fromJson(Map<String, dynamic> map) {
    var types = List<String>.from(map["types"] ?? []).map((item) => HistoryContentType.parse(item)).where((item) => filterTypes.contains(item)).toSet();
    return FilterRule(
      content: map["content"],
      appIds: Set<String>.from(map["appIds"] ?? []),
      types: types,
      needSync: map["needSync"],
      enable: map["enable"],
      ignoreCase: map["ignoreCase"] ?? false,
    );
  }

  FilterRule copyWith({
    String? content,
    Set<String>? appIds,
    Set<HistoryContentType>? types,
    bool? needSync,
    bool? enable,
    bool? ignoreCase,
  }) {
    return FilterRule(
      content: content ?? this.content,
      appIds: appIds ?? this.appIds,
      types: types ?? this.types,
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

    // 检查类型匹配
    final typeMatched = types.contains(type);

    // 如果内容、应用、类型都匹配，则命中规则
    if (contentMatched && appMatched) {
      if (types.isEmpty) {
        // 类型为空则表示命中规则
        return true;
      } else {
        // 否则还要判断类型是否符合
        return typeMatched;
      }
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
      "types": types.map((type) => type.toString()).toList(),
      "needSync": needSync,
      "enable": enable,
      "ignoreCase": ignoreCase,
    };
  }
}
