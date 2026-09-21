import 'package:re_editor/re_editor.dart';

import 'built_in_direct_prompts.dart';
import 'built_in_related_prompts.dart';
import 'custom_direct_prompts.dart';
import 'custom_related_prompts.dart';

const List<CodePrompt> luaAllDirectPrompts = [
  ...luaCustomDirectPrompts,
  ...luaBuiltinDirectPrompts,
];
const Map<String, List<CodePrompt>> luaAllRelatedPrompts = {
  ...luaCustomRelatedPrompts,
  ...luaBuiltinRelatedPrompts,
};
