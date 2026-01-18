import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/models/my_code_keyword_prompt.dart';
import 'package:clipshare/app/data/models/rule/rule_script_content.dart';
import 'package:clipshare/app/handlers/re-editor/code_autocomplete_prompts_builder.dart';
import 'package:clipshare/app/handlers/re-editor/default_code_autocomplete_listview.dart';
import 'package:clipshare/app/widgets/largeText/find.dart';
import 'package:clipshare/app/widgets/largeText/menu.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_highlighting/themes/atom-one-light.dart';
import 'package:re_editor/re_editor.dart';
import 'package:re_highlight/languages/lua.dart';
import 'package:re_highlight/re_highlight.dart';

class CodeEditView extends StatelessWidget {
  final double? height;
  final CodeLineEditingController controller;
  final CodeHighlightThemeMode codeTheme;
  final Mode language;
  final String? languageName;
  final List<MyCodeKeywordPrompt>? keywordPrompts;
  final String? hintText;

  const CodeEditView({
    super.key,
    required this.controller,
    required this.language,
    required this.codeTheme,
    this.languageName,
    this.keywordPrompts,
    this.hintText,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: CodeAutocomplete(
        viewBuilder: (context, notifier, onSelected) {
          return DefaultCodeAutocompleteListView(
            notifier: notifier,
            onSelected: onSelected,
          );
        },
        promptsBuilder: MyCodeAutocompletePromptsBuilder(
          language: language,
          keywordPrompts: keywordPrompts,
        ),
        child: CodeEditor(
          controller: controller,
          wordWrap: true,
          hint: hintText,
          autofocus: true,
          indicatorBuilder: (context, editingController, chunkController, notifier) {
            return Row(
              children: [
                DefaultCodeLineNumber(
                  controller: editingController,
                  notifier: notifier,
                ),
                DefaultCodeChunkIndicator(
                  width: 20,
                  controller: chunkController,
                  notifier: notifier,
                ),
              ],
            );
          },
          findBuilder: (context, controller, readOnly) => CodeFindPanelView(controller: controller, readOnly: readOnly),
          toolbarController: const ContextMenuControllerImpl(),
          sperator: Container(width: 1, color: const Color(0xADADAFB6)),
          style: CodeEditorStyle(
            fontSize: 18,
            hintTextColor: Colors.grey,
            codeTheme: CodeHighlightTheme(
              languages: {languageName ?? language.name!.toLowerCase(): codeTheme},
              theme: atomOneLightTheme,
            ),
          ),
        ),
      ),
    );
  }
}
