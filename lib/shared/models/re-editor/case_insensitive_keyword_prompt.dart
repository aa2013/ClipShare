import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/extensions/string_extension.dart';
import 'package:re_editor/re_editor.dart';

class CaseInsensitiveKeywordPrompt extends CodeKeywordPrompt {
  final TranslationKey? desc;

  const CaseInsensitiveKeywordPrompt({
    required super.word,
    this.desc,
  });

  @override
  bool match(String input) {
    final result = word != input && word.startsWithIgnoreCase(input);
    return result;
  }
}
