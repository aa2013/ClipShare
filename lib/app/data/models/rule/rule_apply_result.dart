import 'dart:convert';

class RuleApplyResult {
  ///通知标题
  final String? title;

  ///内容/通知内容
  final String content;

  ///标签
  final Set<String> tags;

  ///是否阻止同步
  final bool isSyncDisabled;

  ///是否最终规则
  final bool isFinalRule;

  ///提取的内容
  final String? extractedContent;

  ///是否丢弃
  final bool isDropped;

  static const RuleApplyResult discard = RuleApplyResult(
    content: "",
    tags: {},
    isSyncDisabled: false,
    isFinalRule: false,
    isDropped: true,
  );

  const RuleApplyResult({
    required this.content,
    required this.tags,
    required this.isSyncDisabled,
    required this.isFinalRule,
    this.title,
    this.extractedContent,
    this.isDropped = false,
  });

  factory RuleApplyResult.fromJson(result) {
    return RuleApplyResult(
      title: result["title"] as String?,
      content: result["content"] as String,
      tags: (result["tags"] as List<dynamic>).cast<String>().toSet(),
      isSyncDisabled: result["isSyncDisabled"] as bool,
      isFinalRule: result["isFinalRule"] as bool,
      extractedContent: result["extractedContent"] as String?,
      isDropped: result["isDropped"] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "tags": tags.toList(),
      "title": title,
      "content": content,
      "isSyncDisabled": isSyncDisabled,
      "isFinalRule": isFinalRule,
      "extractedContent": extractedContent,
      "isDropped": isDropped,
    };
  }

  @override
  String toString() {
    return jsonEncode(this);
  }
}
