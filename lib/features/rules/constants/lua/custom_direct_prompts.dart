import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/models/re-editor/field_prompt.dart';
import 'package:clipshare/shared/models/re-editor/function_prompt.dart';
import 'package:re_editor/re_editor.dart';

const List<CodePrompt> luaCustomDirectPrompts = [
  FunctionPrompt(
    word: 'print',
    returnType: 'void',
    parameters: {
      'log': 'string',
    },
    desc: TranslationKey.codePromptPrint,
  ),
  FieldPrompt(
    word: 'log',
    type: 'table',
    desc: TranslationKey.codePromptLog,
  ),
  FieldPrompt(
    word: 'json',
    type: 'table',
    desc: TranslationKey.codePromptJson,
  ),
  FieldPrompt(
    word: 'ContentType',
    type: 'table',
    desc: TranslationKey.codePromptContentType,
  ),
  FieldPrompt(
    word: 'params',
    type: 'table',
    desc: TranslationKey.codePromptScriptParams,
  ),
  FieldPrompt(
    word: 'android',
    type: 'table',
    desc: TranslationKey.codePromptPlatformAndroid,
  ),
  FunctionPrompt(
    word: 'notify',
    desc: TranslationKey.codePromptNotify,
    returnType: 'void',
    parameters: {
      'title': 'string',
      'content': 'string',
    },
  ),
  FieldPrompt(
    word: 'Platform',
    type: 'table',
    desc: TranslationKey.codePromptPlatform,
  ),
  FieldPrompt(
    word: 'app',
    type: 'table',
    desc: TranslationKey.codePromptApp,
  ),
  FieldPrompt(
    word: 'self',
    type: 'table',
    desc: TranslationKey.codePromptDeviceSelf,
  ),
  FieldPrompt(
    word: 'crypto',
    type: 'table',
    desc: TranslationKey.codePromptCrypto,
  ),
  FieldPrompt(
    word: 'base64',
    type: 'table',
    desc: TranslationKey.codePromptBase64,
  ),
  FieldPrompt(
    word: 'regex',
    type: 'table',
    desc: TranslationKey.codePromptRegex,
  ),
  FieldPrompt(
    word: 'http',
    type: 'table',
    desc: TranslationKey.codePromptHttp,
  ),
  FieldPrompt(
    word: 'task',
    type: 'table',
    desc: TranslationKey.codePromptTask,
  ),
  FunctionPrompt(
    word: 'async',
    returnType: 'async func',
    desc: TranslationKey.codePromptAsync,
    parameters: {
      'func': 'Function'
    },
  ),
  FunctionPrompt(
    word: 'await',
    returnType: 'any',
    desc: TranslationKey.codePromptAwait,
    parameters: {
      'asyncFunc': 'async func'
    },
  ),
];