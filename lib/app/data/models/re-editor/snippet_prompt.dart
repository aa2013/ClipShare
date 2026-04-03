import 'package:clipshare/app/data/models/re-editor/case_insensitive_keyword_prompt.dart';
import 'package:flutter/material.dart';
import 'package:re_editor/re_editor.dart';

class SnippetPrompt extends CaseInsensitiveKeywordPrompt {
  ///代码片段补全
  final String snippet;

  const SnippetPrompt({
    required super.word,
    required this.snippet,
    super.desc,
  });

  @override
  CodeAutocompleteResult get autocomplete {
    final cursorIndex = snippet.indexOf('\$');

    // 按行拆分
    final lines = snippet.split(RegExp(r'\r?\n'));

    int offset;

    if (cursorIndex >= 0) {
      // $ 前的内容
      final beforeCursor = snippet.substring(0, cursorIndex);

      // 判断是否在第一行
      final isFirstLine = !beforeCursor.contains('\n');

      if (isFirstLine) {
        // 第一行
        offset = beforeCursor.length + 1;
      } else {
        //非第一行 → 默认行为（行末尾）
        offset = lines[0].length;
      }
    } else {
      // 没有 $ → 默认行为
      offset = lines[0].length;
    }

    return CodeAutocompleteResult(
      input: '',
      word: snippet,
      selection: TextSelection.collapsed(offset: offset),
    );
  }

}
