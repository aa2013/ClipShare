import 'dart:convert';

import 'package:clipshare/shared/enums/history_content_type.dart';

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
    var types = List<String>.from(map['types'] ?? []).map((item) => HistoryContentType.parse(item)).where((item) => filterTypes.contains(item)).toSet();
    return FilterRule(
      content: map['content'],
      appIds: Set<String>.from(map['appIds'] ?? []),
      types: types,
      needSync: map['needSync'],
      enable: map['enable'],
      ignoreCase: map['ignoreCase'] ?? false,
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

  @override
  String toString() {
    return jsonEncode(toJson());
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'appIds': appIds.toList(),
      'types': types.map((type) => type.name).toList(),
      'needSync': needSync,
      'enable': enable,
      'ignoreCase': ignoreCase,
    };
  }
}
