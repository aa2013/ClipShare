import 'package:clipshare/app/data/repository/entity/tables/lua_lib.dart';
import 'package:floor/floor.dart';

@dao
abstract class LuaLibDao {
  @insert
  Future<int> addLib(RuleLib lib);

  @update
  Future<int> updateLib(RuleLib lib);

  @Query("delete from RuleLib where libName = :libName")
  Future<int?> remove(String libName);

  @Query("select * from RuleLib where libName = :libName")
  Future<RuleLib?> getByLibName(String libName);

  @Query("select * from RuleLib")
  Future<List<RuleLib>> getAllLibs();
}
