import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/models/re-editor/field_prompt.dart';
import 'package:clipshare/shared/models/re-editor/function_prompt.dart';
import 'package:clipshare/shared/models/re-editor/snippet_prompt.dart';
import 'package:re_editor/re_editor.dart';

//lua原生补全提示
const List<CodePrompt> luaBuiltinDirectPrompts = [
  SnippetPrompt(
    word: 'if',
    snippet: 'if \$condition then\n\t\nend',
    desc: TranslationKey.codePromptIfSnippet,
  ),
  SnippetPrompt(
    word: 'else',
    snippet: 'else \n\t\nend',
    desc: TranslationKey.codePromptElseSnippet,
  ),
  SnippetPrompt(
    word: 'elseif',
    snippet: 'elseif \n\t\nend',
    desc: TranslationKey.codePromptElseIfSnippet,
  ),
  SnippetPrompt(
    word: 'while',
    snippet: 'while \$condition do\n\nend',
    desc: TranslationKey.codePromptWhileSnippet,
  ),
  SnippetPrompt(
    word: 'repeat',
    snippet: 'repeat\n\nuntil \$condition',
    desc: TranslationKey.codePromptRepeatSnippet,
  ),

  // for 数值循环
  SnippetPrompt(
    word: 'for',
    snippet: 'for i = 1, \$n do\n\t\nend',
    desc: TranslationKey.codePromptForSnippet,
  ),

  // for 带步长
  SnippetPrompt(
    word: 'forstep',
    snippet: 'for i = 1, \$n, \$step do\n\t\nend',
    desc: TranslationKey.codePromptForStepSnippet,
  ),

  // ipairs 遍历数组
  SnippetPrompt(
    word: 'ipairs',
    snippet: 'for i, v in ipairs(\$list) do\n\t\nend',
    desc: TranslationKey.codePromptIPairsSnippet,
  ),

  // pairs 遍历 table
  SnippetPrompt(
    word: 'pairs',
    snippet: 'for k, v in pairs(\$t) do\n\t\nend',
    desc: TranslationKey.codePromptPairsSnippet,
  ),

  // function 定义
  SnippetPrompt(
    word: 'func',
    snippet: 'function func()\n\t\nend',
    desc: TranslationKey.codePromptFunctionSnippet,
  ),

  // local function
  SnippetPrompt(
    word: 'lfunc',
    snippet: 'local function func()\n\t\nend',
    desc: TranslationKey.codePromptLocalFunctionSnippet,
  ),

  FieldPrompt(
    word: 'math',
    type: 'table',
    desc: TranslationKey.codePromptMath,
  ),
  FieldPrompt(
    word: 'string',
    type: 'table',
    desc: TranslationKey.codePromptString,
  ),
  FieldPrompt(
    word: 'table',
    type: 'table',
    desc: TranslationKey.codePromptTable,
  ),
  FieldPrompt(
    word: 'utf8',
    type: 'table',
    desc: TranslationKey.codePromptUtf8,
  ),
  FieldPrompt(
    word: 'os',
    type: 'table',
    desc: TranslationKey.codePromptOs,
  ),
  FunctionPrompt(
    word: 'type',
    returnType: 'string',
    parameters: {'v': 'any'},
    desc: TranslationKey.codePromptType,
  ),
  FunctionPrompt(
    word: 'tostring',
    returnType: 'string',
    parameters: {'v': 'any'},
    desc: TranslationKey.codePromptToString,
  ),
  FunctionPrompt(
    word: 'tonumber',
    returnType: 'number?',
    parameters: {'v': 'any'},
    desc: TranslationKey.codePromptToNumber,
  ),
  FunctionPrompt(
    word: 'pairs',
    returnType: 'iterator',
    parameters: {'t': 'table'},
    desc: TranslationKey.codePromptPairs,
  ),
  FunctionPrompt(
    word: 'ipairs',
    returnType: 'iterator',
    parameters: {'t': 'table'},
    desc: TranslationKey.codePromptIpairs,
  ),
  FunctionPrompt(
    word: 'next',
    returnType: 'any',
    parameters: {'t': 'table', 'index': 'any?'},
    desc: TranslationKey.codePromptNext,
  ),
  FunctionPrompt(
    word: 'pcall',
    returnType: 'bool',
    parameters: {'f': 'function'},
    desc: TranslationKey.codePromptPcall,
  ),
  FunctionPrompt(
    word: 'xpcall',
    returnType: 'bool',
    parameters: {'f': 'function', 'err': 'function'},
    desc: TranslationKey.codePromptXpcall,
  ),
  FunctionPrompt(
    word: 'select',
    returnType: 'any',
    parameters: {'index': 'number'},
    desc: TranslationKey.codePromptSelect,
  ),
  FunctionPrompt(
    word: 'assert',
    returnType: 'any',
    parameters: {'v': 'any'},
    desc: TranslationKey.codePromptAssert,
  ),
  FunctionPrompt(
    word: 'error',
    returnType: 'void',
    parameters: {'msg': 'string'},
    desc: TranslationKey.codePromptError,
  ),
  FieldPrompt(
    word: '_VERSION',
    type: 'string',
    desc: TranslationKey.codePromptLuaVersion,
  ),
];