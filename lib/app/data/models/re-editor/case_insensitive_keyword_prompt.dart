import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/utils/extensions/string_extension.dart';
import 'package:re_editor/re_editor.dart';

class CaseInsensitiveKeywordPrompt extends CodeKeywordPrompt {
  final TranslationKey? desc;

  CaseInsensitiveKeywordPrompt({
    required super.word,
    this.desc,
  });

  @override
  bool match(String input) {
    return word != input && word.startsWithIgnoreCase(input);
  }
}
