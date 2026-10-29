
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/models/re-editor/field_prompt.dart';
import 'package:clipshare/shared/models/re-editor/function_prompt.dart';
import 'package:re_editor/re_editor.dart';

const Map<String, List<CodePrompt>> luaCustomRelatedPrompts = {
  'log': [
    FunctionPrompt(
      word: 'info',
      returnType: 'void',
      parameters: {
        'log': 'string',
      },
      desc: TranslationKey.codePromptLogInfo,
    ),
    FunctionPrompt(
      word: 'debug',
      returnType: 'void',
      parameters: {
        'log': 'string',
      },
      desc: TranslationKey.codePromptLogDebug,
    ),
    FunctionPrompt(
      word: 'warn',
      returnType: 'void',
      parameters: {
        'log': 'string',
      },
      desc: TranslationKey.codePromptLogWarn,
    ),
    FunctionPrompt(
      word: 'error',
      returnType: 'void',
      parameters: {
        'log': 'string',
      },
      desc: TranslationKey.codePromptLogError,
    ),
  ],
  'json': [
    FunctionPrompt(
      word: 'encode',
      returnType: 'string',
      parameters: {
        'value': 'table',
      },
      desc: TranslationKey.codePromptJsonDecode,
    ),
    FunctionPrompt(
      word: 'decode',
      returnType: 'table',
      parameters: {
        'json': 'string',
      },
      desc: TranslationKey.codePromptJsonDecode,
    ),
  ],
  'ContentType': [
    FieldPrompt(
      word: 'sms',
      type: 'string',
      desc: TranslationKey.codePromptSmsType,
    ),
    FieldPrompt(
      word: 'text',
      type: 'string',
      desc: TranslationKey.codePromptTextType,
    ),
    FieldPrompt(
      word: 'image',
      type: 'string',
      desc: TranslationKey.codePromptImageType,
    ),
    FieldPrompt(
      word: 'notification',
      type: 'string',
      desc: TranslationKey.codePromptNotificationType,
    ),
  ],
  'params': [
    FieldPrompt(
      word: 'type',
      type: 'ContentType',
      desc: TranslationKey.codePromptParamsContentType,
    ),
    FieldPrompt(
      word: 'source',
      type: 'string?',
      desc: TranslationKey.codePromptParamsContentSource,
    ),
    FieldPrompt(
      word: 'title',
      type: 'string?',
      desc: TranslationKey.codePromptParamsContentNotificationTitle,
    ),
    FieldPrompt(
      word: 'content',
      type: 'string',
      desc: TranslationKey.codePromptParamsContentDetail,
    ),
    FieldPrompt(
      word: 'extractedContent',
      type: 'string?',
      desc: TranslationKey.codePromptParamsContentExtracted,
    ),
    FieldPrompt(
      word: 'tags',
      type: 'table?',
      desc: TranslationKey.codePromptParamsContentTags,
    ),
    FieldPrompt(
      word: 'isSyncDisabled',
      type: 'bool?',
      desc: TranslationKey.codePromptParamsContentIsSyncDisabled,
    ),
  ],
  'android': [
    FunctionPrompt(
      word: 'toast',
      desc: TranslationKey.codePromptAndroidToast,
      returnType: 'void',
      parameters: {'content': 'string'},
    ),
    FunctionPrompt(
      word: 'sendHistoryChangedBroadcast',
      desc: TranslationKey.codePromptAndroidSendHistoryChangedBroadcast,
      returnType: 'void',
      parameters: {
        'type': 'ContentType',
        'content': 'string',
        'from_dev_id': 'string',
        'from_dev_name': 'string',
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
  'http':[
    FunctionPrompt(
      word: 'getAsync',
      returnType: 'table',
      desc: TranslationKey.codePromptHttpGet,
      parameters: {
        'url': 'string',
        'options': 'table',
      },
    ),
    FunctionPrompt(
      word: 'postAsync',
      returnType: 'table',
      desc: TranslationKey.codePromptHttpPost,
      parameters: {
        'url': 'string',
        'options': 'table',
        'body': 'table?',
      },
    ),
    FunctionPrompt(
      word: 'putAsync',
      returnType: 'table',
      desc: TranslationKey.codePromptPut,
      parameters: {
        'url': 'string',
        'options': 'table',
        'body': 'table?',
      },
    ),
    FunctionPrompt(
      word: 'deleteAsync',
      returnType: 'table',
      desc: TranslationKey.codePromptDelete,
      parameters: {
        'url': 'string',
        'options': 'table',
        'body': 'table?',
      },
    ),
  ],
  'task': [
    FunctionPrompt(
      word: 'create',
      returnType: 'task',
      desc: TranslationKey.codePromptTaskCreate,
      parameters: {
      },
    ),
  ]
};