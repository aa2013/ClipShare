
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/models/re-editor/field_prompt.dart';
import 'package:clipshare/shared/models/re-editor/function_prompt.dart';
import 'package:re_editor/re_editor.dart';

//lua原生补全提示
const Map<String, List<CodePrompt>> luaBuiltinRelatedPrompts = {
  // ================= MATH =================
  'math': [
    FunctionPrompt(
      word: 'abs',
      returnType: 'number',
      parameters: {'x': 'number'},
      desc: TranslationKey.codePromptMathAbs,
    ),
    FunctionPrompt(
      word: 'acos',
      returnType: 'number',
      parameters: {'x': 'number'},
      desc: TranslationKey.codePromptMathAcos,
    ),
    FunctionPrompt(
      word: 'asin',
      returnType: 'number',
      parameters: {'x': 'number'},
      desc: TranslationKey.codePromptMathAsin,
    ),
    FunctionPrompt(
      word: 'atan',
      returnType: 'number',
      parameters: {'y': 'number', 'x': 'number?'},
      desc: TranslationKey.codePromptMathAtan,
    ),
    FunctionPrompt(
      word: 'ceil',
      returnType: 'number',
      parameters: {'x': 'number'},
      desc: TranslationKey.codePromptMathCeil,
    ),
    FunctionPrompt(
      word: 'cos',
      returnType: 'number',
      parameters: {'x': 'number'},
      desc: TranslationKey.codePromptMathCos,
    ),
    FunctionPrompt(
      word: 'deg',
      returnType: 'number',
      parameters: {'x': 'number'},
      desc: TranslationKey.codePromptMathDeg,
    ),
    FunctionPrompt(
      word: 'exp',
      returnType: 'number',
      parameters: {'x': 'number'},
      desc: TranslationKey.codePromptMathExp,
    ),
    FunctionPrompt(
      word: 'floor',
      returnType: 'number',
      parameters: {'x': 'number'},
      desc: TranslationKey.codePromptMathFloor,
    ),
    FunctionPrompt(
      word: 'fmod',
      returnType: 'number',
      parameters: {'x': 'number', 'y': 'number'},
      desc: TranslationKey.codePromptMathFmod,
    ),
    FieldPrompt(
      word: 'huge',
      type: 'number',
      desc: TranslationKey.codePromptMathHuge,
    ),
    FunctionPrompt(
      word: 'log',
      returnType: 'number',
      parameters: {'x': 'number', 'base': 'number?'},
      desc: TranslationKey.codePromptMathLog,
    ),
    FunctionPrompt(
      word: 'max',
      returnType: 'number',
      parameters: {'...': 'number'},
      desc: TranslationKey.codePromptMathMax,
    ),
    FieldPrompt(
      word: 'maxinteger',
      type: 'integer',
      desc: TranslationKey.codePromptMathMaxInteger,
    ),
    FunctionPrompt(
      word: 'min',
      returnType: 'number',
      parameters: {'...': 'number'},
      desc: TranslationKey.codePromptMathMin,
    ),
    FieldPrompt(
      word: 'mininteger',
      type: 'integer',
      desc: TranslationKey.codePromptMathMinInteger,
    ),
    FunctionPrompt(
      word: 'modf',
      returnType: 'number, number',
      parameters: {'x': 'number'},
      desc: TranslationKey.codePromptMathModf,
    ),
    FieldPrompt(
      word: 'pi',
      type: 'number',
      desc: TranslationKey.codePromptMathPi,
    ),
    FunctionPrompt(
      word: 'rad',
      returnType: 'number',
      parameters: {'x': 'number'},
      desc: TranslationKey.codePromptMathRad,
    ),
    FunctionPrompt(
      word: 'random',
      returnType: 'number',
      parameters: {'m': 'number?', 'n': 'number?'},
      desc: TranslationKey.codePromptMathRandom,
    ),
    FunctionPrompt(
      word: 'randomseed',
      returnType: 'void',
      parameters: {'x': 'number'},
      desc: TranslationKey.codePromptMathRandomSeed,
    ),
    FunctionPrompt(
      word: 'sin',
      returnType: 'number',
      parameters: {'x': 'number'},
      desc: TranslationKey.codePromptMathSin,
    ),
    FunctionPrompt(
      word: 'sqrt',
      returnType: 'number',
      parameters: {'x': 'number'},
      desc: TranslationKey.codePromptMathSqrt,
    ),
    FunctionPrompt(
      word: 'tan',
      returnType: 'number',
      parameters: {'x': 'number'},
      desc: TranslationKey.codePromptMathTan,
    ),
    FunctionPrompt(
      word: 'tointeger',
      returnType: 'integer?',
      parameters: {'x': 'number'},
      desc: TranslationKey.codePromptMathToInteger,
    ),
    FunctionPrompt(
      word: 'type',
      returnType: 'string?',
      parameters: {'x': 'number'},
      desc: TranslationKey.codePromptMathType,
    ),
    FunctionPrompt(
      word: 'ult',
      returnType: 'bool',
      parameters: {'m': 'integer', 'n': 'integer'},
      desc: TranslationKey.codePromptMathUlt,
    ),
  ],

  // ================= STRING =================
  'string': [
    FunctionPrompt(
      word: 'byte',
      returnType: 'number',
      parameters: {'s': 'string', 'i': 'number?', 'j': 'number?'},
      desc: TranslationKey.codePromptStringByte,
    ),
    FunctionPrompt(
      word: 'char',
      returnType: 'string',
      parameters: {'...': 'number'},
      desc: TranslationKey.codePromptStringChar,
    ),
    FunctionPrompt(
      word: 'dump',
      returnType: 'string',
      parameters: {'func': 'function', 'strip': 'bool?'},
      desc: TranslationKey.codePromptStringDump,
    ),
    FunctionPrompt(
      word: 'len',
      returnType: 'number',
      parameters: {'s': 'string'},
      desc: TranslationKey.codePromptStringLen,
    ),
    FunctionPrompt(
      word: 'sub',
      returnType: 'string',
      parameters: {'s': 'string'},
      desc: TranslationKey.codePromptStringSub,
    ),
    FunctionPrompt(
      word: 'find',
      returnType: 'number',
      parameters: {'s': 'string'},
      desc: TranslationKey.codePromptStringFind,
    ),
    FunctionPrompt(
      word: 'format',
      returnType: 'string',
      parameters: {'fmt': 'string'},
      desc: TranslationKey.codePromptStringFormat,
    ),
    FunctionPrompt(
      word: 'gmatch',
      returnType: 'iterator',
      parameters: {'s': 'string', 'pattern': 'string'},
      desc: TranslationKey.codePromptStringGMatch,
    ),
    FunctionPrompt(
      word: 'gsub',
      returnType: 'string, number',
      parameters: {'s': 'string', 'pattern': 'string', 'repl': 'string|function|table', 'n': 'number?'},
      desc: TranslationKey.codePromptStringGSub,
    ),
    FunctionPrompt(
      word: 'lower',
      returnType: 'string',
      parameters: {'s': 'string'},
      desc: TranslationKey.codePromptStringLower,
    ),
    FunctionPrompt(
      word: 'match',
      returnType: 'any',
      parameters: {'s': 'string', 'pattern': 'string', 'init': 'number?'},
      desc: TranslationKey.codePromptStringMatch,
    ),
    FunctionPrompt(
      word: 'pack',
      returnType: 'string',
      parameters: {'fmt': 'string', '...': 'any'},
      desc: TranslationKey.codePromptStringPack,
    ),
    FunctionPrompt(
      word: 'packsize',
      returnType: 'number',
      parameters: {'fmt': 'string'},
      desc: TranslationKey.codePromptStringPackSize,
    ),
    FunctionPrompt(
      word: 'rep',
      returnType: 'string',
      parameters: {'s': 'string', 'n': 'number', 'sep': 'string?'},
      desc: TranslationKey.codePromptStringRep,
    ),
    FunctionPrompt(
      word: 'reverse',
      returnType: 'string',
      parameters: {'s': 'string'},
      desc: TranslationKey.codePromptStringReverse,
    ),
    FunctionPrompt(
      word: 'upper',
      returnType: 'string',
      parameters: {'s': 'string'},
      desc: TranslationKey.codePromptStringUpper,
    ),
    FunctionPrompt(
      word: 'unpack',
      returnType: 'any',
      parameters: {'fmt': 'string', 's': 'string', 'pos': 'number?'},
      desc: TranslationKey.codePromptStringUnpack,
    ),
  ],

  // ================= TABLE =================
  'table': [
    FunctionPrompt(
      word: 'insert',
      returnType: 'void',
      parameters: {'t': 'table'},
      desc: TranslationKey.codePromptTableInsert,
    ),
    FunctionPrompt(
      word: 'move',
      returnType: 'table',
      parameters: {'a1': 'table', 'f': 'number', 'e': 'number', 't': 'number', 'a2': 'table?'},
      desc: TranslationKey.codePromptTableMove,
    ),
    FunctionPrompt(
      word: 'pack',
      returnType: 'table',
      parameters: {'...': 'any'},
      desc: TranslationKey.codePromptTablePack,
    ),
    FunctionPrompt(
      word: 'remove',
      returnType: 'any',
      parameters: {'t': 'table'},
      desc: TranslationKey.codePromptTableRemove,
    ),
    FunctionPrompt(
      word: 'sort',
      returnType: 'void',
      parameters: {'t': 'table'},
      desc: TranslationKey.codePromptTableSort,
    ),
    FunctionPrompt(
      word: 'concat',
      returnType: 'string',
      parameters: {'t': 'table'},
      desc: TranslationKey.codePromptTableConcat,
    ),
    FunctionPrompt(
      word: 'unpack',
      returnType: 'any',
      parameters: {'t': 'table', 'i': 'number?', 'j': 'number?'},
      desc: TranslationKey.codePromptTableUnpack,
    ),
  ],

  // ================= UTF8 =================
  'utf8': [
    FunctionPrompt(
      word: 'len',
      returnType: 'number',
      parameters: {'s': 'string'},
      desc: TranslationKey.codePromptUtf8Len,
    ),
    FunctionPrompt(
      word: 'char',
      returnType: 'string',
      parameters: {'...': 'number'},
      desc: TranslationKey.codePromptUtf8Char,
    ),
    FieldPrompt(
      word: 'charpattern',
      type: 'string',
      desc: TranslationKey.codePromptUtf8CharPattern,
    ),
    FunctionPrompt(
      word: 'codes',
      returnType: 'iterator',
      parameters: {'s': 'string'},
      desc: TranslationKey.codePromptUtf8Codes,
    ),
    FunctionPrompt(
      word: 'codepoint',
      returnType: 'number',
      parameters: {'s': 'string', 'i': 'number?', 'j': 'number?'},
      desc: TranslationKey.codePromptUtf8CodePoint,
    ),
    FunctionPrompt(
      word: 'offset',
      returnType: 'number?',
      parameters: {'s': 'string', 'n': 'number', 'i': 'number?'},
      desc: TranslationKey.codePromptUtf8Offset,
    ),
  ],

  // ================= OS（安全子集） =================
  'os': [
    FunctionPrompt(
      word: 'clock',
      returnType: 'number',
      parameters: {},
      desc: TranslationKey.codePromptOsClock,
    ),
    FunctionPrompt(
      word: 'date',
      returnType: 'string',
      parameters: {},
      desc: TranslationKey.codePromptOsDate,
    ),
    FunctionPrompt(
      word: 'time',
      returnType: 'number',
      parameters: {},
      desc: TranslationKey.codePromptOsTime,
    ),
    FunctionPrompt(
      word: 'difftime',
      returnType: 'number',
      parameters: {'t1': 'number', 't2': 'number'},
      desc: TranslationKey.codePromptOsDiffTime,
    ),
  ],
};