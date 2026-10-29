import 'package:clipshare/features/rules/constants/lua/all_prompts.dart';
import 'package:clipshare/features/rules/constants/lua/keyword_prompts.dart';
import 'package:clipshare/features/rules/theme/code_theme.dart';
import 'package:clipshare/features/rules/theme/highlight_lua.dart';
import 'package:clipshare/shared/models/re-editor/case_insensitive_keyword_prompt.dart';
import 'package:clipshare/shared/widgets/re-editor/code_edit_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:re_editor/re_editor.dart';

class LuaCodeEditView extends StatelessWidget {
  final Key? editorKey;
  final double? height;
  final CodeLineEditingController controller;
  final VoidCallback onSaveShortcutTriggered;
  final List<CaseInsensitiveKeywordPrompt>? keywordPrompts;
  final List<CodePrompt>? directPrompts;
  final Map<String, List<CodePrompt>>? relatedPrompts;
  final bool autoWrapText;

  const LuaCodeEditView({
    super.key,
    this.editorKey,
    required this.controller,
    required this.onSaveShortcutTriggered,
    this.keywordPrompts = luaKeywordPrompts,
    this.directPrompts = luaAllDirectPrompts,
    this.relatedPrompts = luaAllRelatedPrompts,
    this.height,
    this.autoWrapText = false,
  });

  @override
  Widget build(BuildContext context) {
    return CodeEditView(
      editorKey: editorKey,
      height: height,
      autoWrapText: autoWrapText,
      controller: controller,
      language: langLuaHighlight,
      codeTheme: codeLuaTheme,
      keywordPrompts: keywordPrompts,
      directPrompts: directPrompts,
      relatedPrompts: relatedPrompts,
      shortcutOverrideActions: {
        CodeShortcutSaveIntent: CallbackAction<CodeShortcutSaveIntent>(
          onInvoke: (CodeShortcutSaveIntent intent) {
            onSaveShortcutTriggered();
            return null;
          },
        ),
      },
    );
  }
}
