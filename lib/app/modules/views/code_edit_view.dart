import 'package:clipshare/app/data/models/re-editor/case_insensitive_keyword_prompt.dart';
import 'package:clipshare/app/handlers/re-editor/code_autocomplete_prompts_builder.dart';
import 'package:clipshare/app/widgets/re-editor/default_code_autocomplete_listview.dart';
import 'package:clipshare/app/theme/code_editor_theme.dart';
import 'package:clipshare/app/widgets/largeText/find.dart';
import 'package:clipshare/app/widgets/largeText/menu.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:re_editor/re_editor.dart';
import 'package:re_highlight/re_highlight.dart';

class CodeEditView extends StatelessWidget {
  final double? height;
  final Key? editorKey;
  final CodeLineEditingController controller;
  final CodeHighlightThemeMode codeTheme;
  final Mode language;
  final String? languageName;
  final List<CaseInsensitiveKeywordPrompt>? keywordPrompts;
  final List<CodePrompt>? directPrompts;
  final Map<String, List<CodePrompt>>? relatedPrompts;
  final String? hintText;
  final Map<Type, Action<Intent>>? shortcutOverrideActions;
  final bool autoWrapText;

  const CodeEditView({
    super.key,
    this.editorKey,
    required this.controller,
    required this.language,
    required this.codeTheme,
    this.languageName,
    this.keywordPrompts,
    this.directPrompts,
    this.relatedPrompts,
    this.hintText,
    this.height,
    this.autoWrapText = false,
    this.shortcutOverrideActions,
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
          relatedPrompts: relatedPrompts,
          directPrompts: directPrompts,
        ),
        child: CodeEditor(
          key: editorKey,
          controller: controller,
          wordWrap: autoWrapText,
          hint: hintText,
          autofocus: true,
          shortcutsActivatorsBuilder: const DefaultCodeShortcutsActivatorsBuilder(),
          shortcutOverrideActions: shortcutOverrideActions,
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
            fontSize: 15,
            hintTextColor: Colors.grey,
            codeTheme: CodeHighlightTheme(
              languages: {languageName ?? language.name!.toLowerCase(): codeTheme},
              theme: customCodeLightTheme,
            ),
          ),
        ),
      ),
    );
  }
}
