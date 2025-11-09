import 'dart:ui';

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
    bool casesensitive = false,
  }) {
    if (anchor.isEmpty) {
      return TextSpan(
        text: value,
        style: this,
      );
    }
    final int index;
    if (casesensitive) {
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
