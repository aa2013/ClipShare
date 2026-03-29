import 'package:clipshare/app/theme/re-editor/highlight_lua.dart';
import 'package:clipshare/app/modules/views/code_edit_view.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:re_editor/re_editor.dart';

class LuaCodeEditView extends StatelessWidget {
  final double? height;
  final CodeLineEditingController controller;
  final VoidCallback onSaveShortcutTriggered;

  const LuaCodeEditView({
    super.key,
    required this.controller,
    required this.onSaveShortcutTriggered,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return CodeEditView(
      height: height,
      controller: controller,
      language: langLuaHighlight,
      codeTheme: Constants.codeLuaTheme,
      keywordPrompts: Constants.luaKeywordPrompts,
      directPrompts: Constants.luaDirectPrompts,
      relatedPrompts: Constants.luaRelatedPrompts,
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
