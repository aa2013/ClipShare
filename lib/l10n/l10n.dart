/// 国际化模块统一出口。
///
/// 集中导出 gen-l10n 生成的 [AppLocalizations] 及相关枚举，业务代码统一
/// 从本文件导入，避免直接依赖生成目录或 shared 下的分散枚举。
library;

export 'app_language.dart';
export 'gen/app_localizations.dart';
export 'translation_key.dart';
