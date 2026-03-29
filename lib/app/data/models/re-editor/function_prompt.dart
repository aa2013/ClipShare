import 'package:clipshare/app/data/models/re-editor/case_insensitive_keyword_prompt.dart';
import 'package:clipshare/app/utils/extensions/string_extension.dart';
import 'package:re_editor/re_editor.dart';

class FunctionPrompt extends CaseInsensitiveKeywordPrompt {
  final String returnType;
  final Map<String, String> parameters;

  FunctionPrompt({
    required super.word,
    required this.returnType,
    required this.parameters,
    super.desc,
  });

  @override
  CodeAutocompleteResult get autocomplete {
    final keys = parameters.keys
        .map((key) {
          if (parameters[key]?.equalsIgnoreCase("string") ?? false) {
            return "'$key'";
          }
          return key;
        })
        .join(", ");
    return CodeAutocompleteResult.fromWord("$word($keys)");
  }
}
