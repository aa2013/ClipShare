import 'dart:convert';

import 'package:clipshare/shared/enums/history_content_type.dart';

class SearchFilter {
  String content;
  String startDate;
  String endDate;
  Set<String> tags = {};
  Set<String> devIds = {};
  Set<String> appIds = {};
  bool onlyNoSync;
  HistoryContentType type;

  SearchFilter({
    this.content = '',
    this.startDate = '',
    this.endDate = '',
    Set<String>? tags,
    Set<String>? devIds,
    Set<String>? appIds,
    this.onlyNoSync = false,
    this.type = HistoryContentType.all,
  }) {
    this.tags = tags ?? {};
    this.devIds = devIds ?? {};
    this.appIds = appIds ?? {};
  }

  factory SearchFilter.fromJson(Map<String, dynamic> json) {
    return SearchFilter()
      ..content = json['content']
      ..startDate = json['startDate']
      ..endDate = json['endDate']
      ..tags = (json['tags'] as List<dynamic>? ?? []).map((e) => e.toString()).toSet()
      ..devIds = (json['devIds'] as List<dynamic>? ?? []).map((e) => e.toString()).toSet()
      ..appIds = (json['appIds'] as List<dynamic>? ?? []).map((e) => e.toString()).toSet()
      ..onlyNoSync = json['onlyNoSync']
      ..type = HistoryContentType.parse(json['type']);
  }

  /// 返回新的筛选条件副本；集合字段深拷贝，调用方可安全级联修改。
  SearchFilter copyWith({
    String? content,
    String? startDate,
    String? endDate,
    Set<String>? tags,
    Set<String>? devIds,
    Set<String>? appIds,
    bool? onlyNoSync,
    HistoryContentType? type,
  }) {
    return SearchFilter(
      content: content ?? this.content,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      tags: tags ?? Set.of(this.tags),
      devIds: devIds ?? Set.of(this.devIds),
      appIds: appIds ?? Set.of(this.appIds),
      onlyNoSync: onlyNoSync ?? this.onlyNoSync,
      type: type ?? this.type,
    );
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'startDate': startDate,
      'endDate': endDate,
      'tags': tags.toList(),
      'devIds': devIds.toList(),
      'appIds': appIds.toList(),
      'onlyNoSync': onlyNoSync,
      'type': type.value,
    };
  }
}
