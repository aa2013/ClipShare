import 'package:clipshare/app/data/models/blacklist_item.dart';

class BlackListMatchResult {
  final bool matched;
  final BlackListRule? rule;
  static const notMatched = BlackListMatchResult._private(matched: false, rule: null);

  const BlackListMatchResult._private({required this.matched, required this.rule});

  factory BlackListMatchResult.matched(BlackListRule rule) {
    return BlackListMatchResult._private(matched: true, rule: rule);
  }
}
