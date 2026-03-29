import 'package:clipshare/app/data/repository/entity/tables/rule.dart';
import 'package:floor/floor.dart';

@dao
abstract class RuleDao {
  ///添加规则
  @Insert(onConflict: OnConflictStrategy.ignore)
  Future<int> addRule(Rule rule);

  ///添加规则
  @Insert(onConflict: OnConflictStrategy.ignore)
  Future<List<int>> addRules(List<Rule> rule);

  ///更新规则
  @update
  Future<int> updateRule(Rule rule);

  ///更新规则
  @update
  Future<int> updateRules(List<Rule> rules);

  ///删除规则
  @Query("delete from rule where id = :id")
  Future<int?> remove(int id);

  ///通过 id 查询
  @Query("select * from rule where id = :id")
  Future<Rule?> getById(int id);

  ///查询所有
  @Query("select * from rule order by `order`")
  Future<List<Rule>> getAllRules();
}
