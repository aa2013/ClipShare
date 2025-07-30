import 'dart:convert';

class BlackListRule {
  final String content;
  final Set<String> appIds;
  final bool needSync;
  final bool enable;
  final bool ignoreCase;

  bool get isAllApp => appIds.isEmpty;

  bool get isAllContent => content.isEmpty;

  BlackListRule({
    required this.content,
    required this.appIds,
    required this.needSync,
    required this.enable,
    this.ignoreCase = false,
  });

  factory BlackListRule.fromJson(Map<String, dynamic> map) {
    return BlackListRule(
      content: map["content"],
      appIds: Set<String>.from(map["appIds"] ?? []),
      needSync: map["needSync"],
      enable: map["enable"],
      ignoreCase: map["ignoreCase"]??false,
    );
  }

  BlackListRule copyWith({
    String? content,
    Set<String>? appIds,
    bool? needSync,
    bool? enable,
    bool? ignoreCase,
  }) {
    return BlackListRule(
      content: content ?? this.content,
      appIds: appIds ?? this.appIds,
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
      "content": content,
      "appIds": appIds.toList(),
      "needSync": needSync,
      "enable": enable,
      "ignoreCase": ignoreCase,
    };
  }
}
