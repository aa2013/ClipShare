import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/models/re-editor/case_insensitive_keyword_prompt.dart';
import 'package:clipshare/app/data/models/re-editor/field_prompt.dart';
import 'package:clipshare/app/data/models/re-editor/function_prompt.dart';
import 'package:clipshare/app/data/models/re-editor/snippet_prompt.dart';
import 'package:re_editor/re_editor.dart';

//region lua key prompt

const List<CaseInsensitiveKeywordPrompt> luaKeywordPrompts = [];
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
    type: "table",
    desc: TranslationKey.codePromptLog,
  ),
  FieldPrompt(
    word: 'json',
    type: "table",
    desc: TranslationKey.codePromptJson,
  ),
  FieldPrompt(
    word: 'ContentType',
    type: "table",
    desc: TranslationKey.codePromptContentType,
  ),
  FieldPrompt(
    word: 'params',
    type: "table",
    desc: TranslationKey.codePromptScriptParams,
  ),
  FieldPrompt(
    word: 'android',
    type: "table",
    desc: TranslationKey.codePromptPlatformAndroid,
  ),
  FunctionPrompt(
    word: 'notify',
    desc: TranslationKey.codePromptNotify,
    returnType: 'void',
    parameters: {
      "title": "string",
      "content": "string",
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
];
const Map<String, List<CodePrompt>> luaCustomRelatedPrompts = {
  'log': [
    FunctionPrompt(
      word: 'info',
      returnType: 'void',
      parameters: {
        "log": "string",
      },
      desc: TranslationKey.codePromptLogInfo,
    ),
    FunctionPrompt(
      word: 'debug',
      returnType: 'void',
      parameters: {
        "log": "string",
      },
      desc: TranslationKey.codePromptLogDebug,
    ),
    FunctionPrompt(
      word: 'warn',
      returnType: 'void',
      parameters: {
        "log": "string",
      },
      desc: TranslationKey.codePromptLogWarn,
    ),
    FunctionPrompt(
      word: 'error',
      returnType: 'void',
      parameters: {
        "log": "string",
      },
      desc: TranslationKey.codePromptLogError,
    ),
  ],
  'json': [
    FunctionPrompt(
      word: 'encode',
      returnType: 'string',
      parameters: {
        "value": "table",
      },
      desc: TranslationKey.codePromptJsonDecode,
    ),
    FunctionPrompt(
      word: 'decode',
      returnType: 'table',
      parameters: {
        "json": "string",
      },
      desc: TranslationKey.codePromptJsonDecode,
    ),
  ],
  'ContentType': [
    FieldPrompt(
      word: "sms",
      type: "string",
      desc: TranslationKey.codePromptSmsType,
    ),
    FieldPrompt(
      word: "text",
      type: "string",
      desc: TranslationKey.codePromptTextType,
    ),
    FieldPrompt(
      word: "image",
      type: "string",
      desc: TranslationKey.codePromptImageType,
    ),
    FieldPrompt(
      word: "notification",
      type: "string",
      desc: TranslationKey.codePromptNotificationTpye,
    ),
  ],
  'params': [
    FieldPrompt(
      word: "type",
      type: "ContentType",
      desc: TranslationKey.codePromptParamsContentTpye,
    ),
    FieldPrompt(
      word: "source",
      type: "string?",
      desc: TranslationKey.codePromptParamsContentSouce,
    ),
    FieldPrompt(
      word: "title",
      type: "string?",
      desc: TranslationKey.codePromptParamsContentNotificationTitle,
    ),
    FieldPrompt(
      word: "content",
      type: "string",
      desc: TranslationKey.codePromptParamsContentDetail,
    ),
    FieldPrompt(
      word: "extractedContent",
      type: "string?",
      desc: TranslationKey.codePromptParamsContentExtracted,
    ),
    FieldPrompt(
      word: "tags",
      type: "table?",
      desc: TranslationKey.codePromptParamsContentTags,
    ),
    FieldPrompt(
      word: "isSyncDisabled",
      type: "bool?",
      desc: TranslationKey.codePromptParamsContentIsSyncDisabled,
    ),
  ],
  'android': [
    FunctionPrompt(
      word: 'notifyMediaScan',
      desc: TranslationKey.codePromptAndroidNotifyMediaScan,
      returnType: 'void',
      parameters: {"imagePath": "string"},
    ),
    FunctionPrompt(
      word: 'toast',
      desc: TranslationKey.codePromptAndroidToast,
      returnType: 'void',
      parameters: {"content": "string"},
    ),
    FunctionPrompt(
      word: 'sendHistoryChangedBroadcast',
      desc: TranslationKey.codePromptAndroidSendHistoryChangedBroadcast,
      returnType: 'void',
      parameters: {
        "type": 'ContentType',
        "content": "string",
        "from_dev_id": "string",
        "from_dev_name": "string",
      },
    ),
  ],
  'Platform': [
    FieldPrompt(
      word: 'isAndroid',
      type: 'bool',
      desc: TranslationKey.codePromptPlatformIsAndroid,
    ),
    FieldPrompt(
      word: 'isIOS',
      type: 'bool',
      desc: TranslationKey.codePromptPlatformIsIOS,
    ),
    FieldPrompt(
      word: 'isWindows',
      type: 'bool',
      desc: TranslationKey.codePromptPlatformIsWindows,
    ),
    FieldPrompt(
      word: 'isMacOS',
      type: 'bool',
      desc: TranslationKey.codePromptPlatformIsMacOS,
    ),
    FieldPrompt(
      word: 'isLinux',
      type: 'bool',
      desc: TranslationKey.codePromptPlatformIsLinux,
    ),
  ],
  'app': [
    FieldPrompt(
      word: 'versionName',
      type: 'string',
      desc: TranslationKey.codePromptAppVersionName,
    ),
    FieldPrompt(
      word: 'versionNumber',
      type: 'int',
      desc: TranslationKey.codePromptAppVersionNumber,
    ),
  ],
  'self': [
    FieldPrompt(
      word: 'devId',
      type: 'string',
      desc: TranslationKey.codePromptDeviceSelfId,
    ),
    FieldPrompt(
      word: 'devName',
      type: 'string',
      desc: TranslationKey.codePromptDeviceSelfName,
    ),
  ],
  'crypto': [
    FunctionPrompt(
      word: 'calcMD5',
      returnType: 'string',
      desc: TranslationKey.codePromptCryptoMD5,
      parameters: {
        'content':'string'
      },
    ),
    FunctionPrompt(
      word: 'calcSHA1',
      returnType: 'string',
      parameters: {
        'content':'string'
      },
      desc: TranslationKey.codePromptCryptoSHA1,
    ),
    FunctionPrompt(
      word: 'calcSHA256',
      returnType: 'string',
      parameters: {
        'content':'string'
      },
      desc: TranslationKey.codePromptCryptoSHA256,
    ),
  ],
  'base64': [
    FunctionPrompt(
      word: 'encode',
      returnType: 'string',
      desc: TranslationKey.codePromptBase64Encode,
      parameters: {
        'content':'string'
      },
    ),
    FunctionPrompt(
      word: 'decode',
      returnType: 'string',
      parameters: {
        'content':'string'
      },
      desc: TranslationKey.codePromptBase64Decode,
    ),
  ],
  'regex': [
    FunctionPrompt(
      word: 'match',
      returnType: 'table',
      desc: TranslationKey.codePromptRegexMatch,
      parameters: {
        'content': 'string',
        'pattern': 'string',
        'caseSensitive': 'bool',
        'multiLines': 'bool',
        'dotAll': 'bool',
      },
    ),
    FunctionPrompt(
      word: 'matchGroups',
      returnType: 'table',
      desc: TranslationKey.codePromptRegexMatchGroups,
      parameters: {
        'content': 'string',
        'pattern': 'string',
        'caseSensitive': 'bool',
        'multiLines': 'bool',
        'dotAll': 'bool',
      },
    ),
  ],
};

//lua原生补全提示
const List<CodePrompt> luaBuiltinDirectPrompts = [
  SnippetPrompt(
    word: 'if',
    snippet: "if \$condition then\n\t\nend",
    desc: TranslationKey.codePromptIfSnippet,
  ),
  SnippetPrompt(
    word: 'else',
    snippet: "else \n\t\nend",
    desc: TranslationKey.codePromptElseSnippet,
  ),
  SnippetPrompt(
    word: 'elseif',
    snippet: "elseif \n\t\nend",
    desc: TranslationKey.codePromptElseIfSnippet,
  ),
  SnippetPrompt(
    word: 'while',
    snippet: "while \$condition do\n\nend",
    desc: TranslationKey.codePromptWhileSnippet,
  ),
  SnippetPrompt(
    word: 'repeat',
    snippet: "repeat\n\nuntil \$condition",
    desc: TranslationKey.codePromptRepeatSnippet,
  ),

  // for 数值循环
  SnippetPrompt(
    word: 'for',
    snippet: "for i = 1, \$n do\n\t\nend",
    desc: TranslationKey.codePromptForSnippet,
  ),

  // for 带步长
  SnippetPrompt(
    word: 'forstep',
    snippet: "for i = 1, \$n, \$step do\n\t\nend",
    desc: TranslationKey.codePromptForStepSnippet,
  ),

  // ipairs 遍历数组
  SnippetPrompt(
    word: 'ipairs',
    snippet: "for i, v in ipairs(\$list) do\n\t\nend",
    desc: TranslationKey.codePromptIPairsSnippet,
  ),

  // pairs 遍历 table
  SnippetPrompt(
    word: 'pairs',
    snippet: "for k, v in pairs(\$t) do\n\t\nend",
    desc: TranslationKey.codePromptPairsSnippet,
  ),

  // function 定义
  SnippetPrompt(
    word: 'func',
    snippet: "function func()\n\t\nend",
    desc: TranslationKey.codePromptFunctionSnippet,
  ),

  // local function
  SnippetPrompt(
    word: 'lfunc',
    snippet: "local function func()\n\t\nend",
    desc: TranslationKey.codePromptLocalFunctionSnippet,
  ),

  FieldPrompt(
    word: 'math',
    type: "table",
    desc: TranslationKey.codePromptMath,
  ),
  FieldPrompt(
    word: 'string',
    type: "table",
    desc: TranslationKey.codePromptString,
  ),
  FieldPrompt(
    word: 'table',
    type: "table",
    desc: TranslationKey.codePromptTable,
  ),
  FieldPrompt(
    word: 'utf8',
    type: "table",
    desc: TranslationKey.codePromptUtf8,
  ),
  FieldPrompt(
    word: 'os',
    type: "table",
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

//endregion

const List<CodePrompt> luaAllDirectPrompts = [
  ...luaCustomDirectPrompts,
  ...luaBuiltinDirectPrompts,
];
const Map<String, List<CodePrompt>> luaAllRelatedPrompts = {
  ...luaCustomRelatedPrompts,
  ...luaBuiltinRelatedPrompts,
};
