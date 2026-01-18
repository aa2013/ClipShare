import 'package:clipshare/app/data/models/my_code_keyword_prompt.dart';
import 'package:clipshare/app/utils/extensions/string_extension.dart';
import 'package:flutter/material.dart';
import 'package:re_editor/re_editor.dart';
import 'package:re_highlight/re_highlight.dart';

class MyCodeAutocompletePromptsBuilder implements DefaultCodeAutocompletePromptsBuilder {
  final Mode? language;
  late final List<MyCodeKeywordPrompt> keywordPrompts;
  late final List<CodePrompt> directPrompts;
  late final Map<String, List<CodePrompt>> relatedPrompts;

  final Set<CodePrompt> _allKeywordPrompts = {};

  MyCodeAutocompletePromptsBuilder({
    this.language,
    List<MyCodeKeywordPrompt>? keywordPrompts,
    List<CodePrompt>? directPrompts,
    Map<String, List<CodePrompt>>? relatedPrompts,
  }) {
    this.keywordPrompts = keywordPrompts ?? [];
    this.directPrompts = directPrompts ?? [];
    this.relatedPrompts = relatedPrompts ?? {};
    _allKeywordPrompts.addAll(this.keywordPrompts);
    _allKeywordPrompts.addAll(this.directPrompts);
    final dynamic keywords = language?.keywords;
    if (keywords is Map) {
      final dynamic keywordContent = keywords['keyword'];
      late final List<dynamic> keywordList;
      if (keywordContent is! List) {
        keywordList = keywordContent.toString().split(' ');
      } else {
        keywordList = keywordContent;
      }
      _allKeywordPrompts.addAll(keywordList.map((keyword) => MyCodeKeywordPrompt(word: keyword)));

      final dynamic builtInContent = keywords['built_in'];
      late final List<dynamic> builtInList;
      if (builtInContent is! List) {
        builtInList = builtInContent.toString().split(' ');
      } else {
        builtInList = builtInContent;
      }
      _allKeywordPrompts.addAll(builtInList.map((keyword) => MyCodeKeywordPrompt(word: keyword)));

      final dynamic literalContent = keywords['literal'];
      late final List<dynamic> literalList;
      if (literalContent is! List) {
        literalList = literalContent.toString().split(' ');
      } else {
        literalList = literalContent;
      }
      _allKeywordPrompts.addAll(literalList.map((keyword) => MyCodeKeywordPrompt(word: keyword)));

      final dynamic typeContent = keywords['type'];
      late final List<dynamic> typeList;
      if (typeContent is! List) {
        typeList = typeContent.toString().split(' ');
      } else {
        typeList = typeContent;
      }
      _allKeywordPrompts.addAll(typeList.map((keyword) => MyCodeKeywordPrompt(word: keyword)));
    }
  }

  @override
  CodeAutocompleteEditingValue? build(BuildContext context, CodeLine codeLine, CodeLineSelection selection) {
    final String text = codeLine.text;
    final Characters charactersBefore = text.substring(0, selection.extentOffset).characters;
    if (charactersBefore.isEmpty) {
      return null;
    }
    final Characters charactersAfter = text.substring(selection.extentOffset).characters;
    // FIXME：Check whether the position is inside a string
    if (charactersBefore.containsSymbols(const ['\'', '"']) && charactersAfter.containsSymbols(const ['\'', '"'])) {
      return null;
    }
    // TODO Should check operator `->` for some languages like c/c++
    final Iterable<CodePrompt> prompts;
    final String input;
    if (charactersBefore.takeLast(1).string == '.') {
      input = '';
      int start = charactersBefore.length - 2;
      for (; start >= 0; start--) {
        if (!charactersBefore.elementAt(start).isValidVariablePart) {
          break;
        }
      }
      final String target = charactersBefore.getRange(start + 1, charactersBefore.length - 1).string;
      prompts = relatedPrompts[target] ?? const [];
    } else {
      int start = charactersBefore.length - 1;
      for (; start >= 0; start--) {
        if (!charactersBefore.elementAt(start).isValidVariablePart) {
          break;
        }
      }
      input = charactersBefore.getRange(start + 1, charactersBefore.length).string;
      if (input.isEmpty) {
        return null;
      }
      if (start > 0 && charactersBefore.elementAt(start) == '.') {
        final int mark = start;
        for (start = start - 1; start >= 0; start--) {
          if (!charactersBefore.elementAt(start).isValidVariablePart) {
            break;
          }
        }
        final String target = charactersBefore.getRange(start + 1, mark).string;
        prompts = relatedPrompts[target]?.where((prompt) => prompt.match(input)) ?? const [];
      } else {
        prompts = _allKeywordPrompts.where((prompt) => prompt.match(input));
      }
    }
    if (prompts.isEmpty) {
      return null;
    }
    return CodeAutocompleteEditingValue(input: input, prompts: prompts.toList(), index: 0);
  }
}
