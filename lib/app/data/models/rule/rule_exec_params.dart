import 'dart:convert';

import 'package:clipshare/app/data/enums/history_content_type.dart';
import 'package:clipshare/app/data/enums/white_black_mode.dart';
import 'package:clipshare/app/data/models/rule/rule_apply_result.dart';
import 'package:clipshare/app/data/models/rule/rule_item.dart';
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

  //存储所有白名单结果，对于白名单规则，只要有一个白名单通过则算通过
  final Set<bool> _whitelistDroppedResults = {};

  ///判断白名单是否丢弃：白名单结果为 1，且存在 true
  bool get whitelistDropped => _whitelistDroppedResults.length == 1 && _whitelistDroppedResults.contains(true);

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

  void merge(RuleItem rule, RuleApplyResult result) {
    title = result.title;
    content = result.content;
    if (result.tags.isNotEmpty) {
      tags ??= {};
      tags!.addAll(result.tags);
    }
    preventSync |= result.isSyncDisabled;
    _isFinal |= result.isFinalRule;
    if (result.extractedContent != null) {
      extracted = result.extractedContent;
    }
    if (rule.isUseRegex && rule.regex.mode == WhiteBlackMode.white) {
      _whitelistDroppedResults.add(result.isDropped);
    } else {
      isDrop |= result.isDropped;
    }
  }

  RuleApplyResult toApplyResult({
    bool? drop,
    bool? isFinal,
  }) {
    return RuleApplyResult(
      title: title,
      content: content,
      tags: tags ?? {},
      isSyncDisabled: preventSync,
      isFinalRule: isFinal ?? _isFinal,
      isDropped: drop ?? isDrop || whitelistDropped,
      extractedContent: extracted,
    );
  }
}
