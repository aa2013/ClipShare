import 'dart:convert';

@Deprecated("1.5.0版本起不再使用，改为使用 RuleItem")
class Rule {
  final String name;
  final String rule;

  const Rule({required this.name, required this.rule});

  static List<Rule> fromJson(List<Map<String, dynamic>> json) {
    List<Rule> list = List.empty(growable: true);
    for (var r in json) {
      list.add(Rule(name: r['name']!, rule: r['rule']!));
    }
    return list;
  }

  Map<String, String> toJson() {
    return {
      "name": name,
      "rule": rule,
    };
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }

  @override
  int get hashCode => name.hashCode;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Rule && runtimeType == other.runtimeType && name == other.name;
}
