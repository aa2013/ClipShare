import 'dart:ui';

import 'package:clipshare/app/data/models/re-editor/field_prompt.dart';
import 'package:clipshare/app/data/models/re-editor/function_prompt.dart';
import 'package:clipshare/app/data/models/re-editor/snippet_prompt.dart';
import 'package:flutter/material.dart';
import 'package:re_editor/re_editor.dart';

extension CodePromptExtension on CodePrompt {
  InlineSpan createSpan(BuildContext context, String input) {
    const TextStyle style = TextStyle();
    final InlineSpan span = style.createSpan(
      value: word,
      anchor: input,
      color: Colors.blue,
      otherColor: Colors.black,
      fontWeight: FontWeight.bold,
    );
    //re-editor自带字段补全
    final CodePrompt prompt = this;
    if (prompt is CodeFieldPrompt) {
      return TextSpan(
        children: [
          span,
          TextSpan(
            text: ' ${prompt.type}',
            style: style.copyWith(color: Colors.cyan),
          ),
        ],
      );
    }
    //re-editor自带函数补全，无括号和参数补全
    if (prompt is CodeFunctionPrompt) {
      return TextSpan(
        children: [
          span,
          TextSpan(
            text: '(...) -> ${prompt.type}',
            style: style.copyWith(color: Colors.cyan),
          ),
        ],
      );
    }
    //函数+参数补全，带注释
    if (prompt is FunctionPrompt) {
      String parameters = prompt.parameters.entries.map((pair)=>"${pair.value} ${pair.key}").join(", ");
      return TextSpan(
        children: [
          span,
          TextSpan(
            text: ' ($parameters) -> ${prompt.returnType}',
            style: style.copyWith(color: Colors.cyan),
          ),
        ],
      );
    }
    //字段补全，带注释
    if (prompt is FieldPrompt) {
      return TextSpan(
        children: [
          span,
          TextSpan(
            text: ' ${prompt.type}',
            style: style.copyWith(color: Colors.cyan),
          ),
        ],
      );
    }
    //代码模板补全
    if(prompt is SnippetPrompt){
      return TextSpan(
        children: [
          span,
          TextSpan(
            text: ' ${prompt.snippet}',
            style: style.copyWith(color: Colors.cyan),
          ),
        ],
      );
    }
    return span;
  }
}

extension TextStyleExtension on TextStyle {
  InlineSpan createSpan({
    required String value,
    required String anchor,
    required Color color,
    Color? otherColor,
    FontWeight? fontWeight,
    bool caseSensitive = false,
  }) {
    if (anchor.isEmpty) {
      return TextSpan(
        text: value,
        style: copyWith(color: otherColor),
      );
    }
    final int index;
    if (caseSensitive) {
      index = value.indexOf(anchor);
    } else {
      index = value.toLowerCase().indexOf(anchor.toLowerCase());
    }
    if (index < 0) {
      return TextSpan(
        text: value,
        style: this,
      );
    }
    return TextSpan(
      children: [
        TextSpan(text: value.substring(0, index), style: this),
        TextSpan(
          text: value.substring(index, index + anchor.length),
          style: copyWith(
            color: color,
            fontWeight: fontWeight,
          ),
        ),
        TextSpan(
          text: value.substring(index + anchor.length),
          style: copyWith(color: otherColor),
        ),
      ],
    );
  }
}

extension CodeAutocompleteResultExt on CodeAutocompleteResult {
  CodeAutocompleteResult copyWith({String? input, String? word, TextSelection? selection}) {
    return CodeAutocompleteResult(
      input: input ?? this.input,
      word: word ?? this.word,
      selection: selection ?? this.selection,
    );
  }
}
