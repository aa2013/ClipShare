import 'dart:convert';

import 'package:clipshare/app/data/enums/history_content_type.dart';
import 'package:clipshare/app/data/models/rule/rule_apply_result.dart';
import 'package:clipshare_clipboard_listener/models/clipboard_source.dart';

///规则执行参数
class RuleExecParams {
  String? title;
  String content;
  HistoryContentType type;
  Set<String>? tags;
  ClipboardSource? source;
  bool preventSync;
  String? extracted;
  bool isDrop;
  bool _isFinal = false;

  RuleExecParams({
    required this.type,
    required this.content,
    this.title,
    this.source,
    this.tags,
    this.preventSync = false,
    this.extracted,
    this.isDrop = false,
  });

  Map<String, dynamic> toJson() {
    return {
      "type": type.name,
      "title": title,
      "content": content,
      "source": source?.id,
      "tags": tags?.toList(),
      "preventSync": preventSync,
      "extracted": extracted,
      "isDrop": isDrop,
    };
  }

  @override
  String toString() {
    return jsonEncode(this);
  }

  void merge(RuleApplyResult result) {
    title = result.title;
    content = result.content;
    if (result.tags.isNotEmpty) {
      tags ??= {};
      tags!.addAll(result.tags);
    }
    preventSync |= result.isSyncDisabled;
    isDrop |= result.isDropped;
    _isFinal |= result.isFinalRule;
    if (result.extractedContent != null) {
      extracted = result.extractedContent;
    }
  }

  RuleApplyResult toApplyResult() {
    return RuleApplyResult(
      title: title,
      content: content,
      tags: tags ?? {},
      isSyncDisabled: preventSync,
      isFinalRule: _isFinal,
      isDropped: isDrop,
      extractedContent: extracted,
    );
  }
}
