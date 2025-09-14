import 'package:re_editor/re_editor.dart';

class MyCodeKeywordPrompt extends CodeKeywordPrompt {
  MyCodeKeywordPrompt({required super.word});

  @override
  bool match(String input) {
    return word != input && word.toLowerCase().startsWith(input.toLowerCase());
  }
}
