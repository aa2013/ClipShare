import 'package:clipshare/app/data/repository/db/app_database.dart';
import 'package:clipshare/app/data/repository/db/app_tables.dart';
import 'package:clipshare/app/data/repository/entity/tables/rule.dart';
import 'package:drift/drift.dart';

part 'rule_dao.g.dart';

@DriftAccessor(tables: [Rules])
class RuleDao extends DatabaseAccessor<AppDatabase> with _$RuleDaoMixin {
  RuleDao(super.attachedDatabase);

  /// 添加或替换单条规则。
  Future<int> addRule(Rule rule) {
    return into(rules).insertOnConflictUpdate(_companion(rule));
  }

  /// 批量添加或替换规则，返回每条规则的 rowId。
  Future<List<int>> addRules(List<Rule> rule) async {
    final result = <int>[];
    for (final item in rule) {
      result.add(await addRule(item));
    }
    return result;
  }

  /// 更新单条规则。
  Future<int> updateRule(Rule rule) {
    return (update(rules)..where((tbl) => tbl.id.equals(rule.id))).write(_companion(rule));
  }

  /// 批量更新规则，返回受影响总行数。
  Future<int> updateRules(List<Rule> rules) async {
    var total = 0;
    for (final item in rules) {
      total += await updateRule(item);
    }
    return total;
  }

  /// 删除指定规则。
  Future<int?> remove(int id) {
    return (delete(rules)..where((tbl) => tbl.id.equals(id))).go();
  }

  /// 通过 id 查询规则。
  Future<Rule?> getById(int id) {
    return (select(rules)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  /// 按规则排序字段读取全部规则。
  Future<List<Rule>> getAllRules() {
    return (select(rules)..orderBy([(tbl) => OrderingTerm.asc(tbl.order)])).get();
  }

  /// 统计规则数量。
  Future<int?> count() async {
    final countExp = countAll();
    final row = await (selectOnly(rules)..addColumns([countExp])).getSingle();
    return row.read<int>(countExp);
  }

  /// 将规则领域对象转换为旧表结构对应的 Drift 写入对象。
  RulesCompanion _companion(Rule rule) {
    return RulesCompanion.insert(
      id: Value(rule.id),
      name: rule.name,
      platforms: rule.platforms,
      sources: rule.sources,
      trigger: rule.trigger,
      type: rule.type,
      regexWhiteBlackMode: Value<String?>(rule.regexWhiteBlackMode),
      regexMain: rule.regexMain,
      regexAllowExtractData: rule.regexAllowExtractData,
      regexExtractedContent: rule.regexExtractedContent,
      regexAllowAddTag: rule.regexAllowAddTag,
      regexTags: rule.regexTags,
      regexIsSyncDisabled: rule.regexIsSyncDisabled,
      regexIsFinalRule: rule.regexIsFinalRule,
      scriptLanguage: rule.scriptLanguage,
      scriptContent: rule.scriptContent,
      version: rule.version,
      enabled: rule.enabled,
      order: rule.order,
    );
  }
}
