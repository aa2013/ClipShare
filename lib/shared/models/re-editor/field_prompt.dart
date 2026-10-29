
import 'case_insensitive_keyword_prompt.dart';

class FieldPrompt extends CaseInsensitiveKeywordPrompt {
  final String type;

  const FieldPrompt({
    required super.word,
    required this.type,
    super.desc,
  });
}
