import 'package:clipshare/app/data/repository/entity/tables/lua_lib.dart';
import 'package:floor/floor.dart';

@dao
abstract class LuaLibDao {
  @insert
  Future<int> addLib(LuaLib lib);

  @update
  Future<int> updateLib(LuaLib lib);

  @Query("delete from LuaLib where libName = :libName")
  Future<int?> remove(String libName);

  @Query("select * from LuaLib where libName = :libName")
  Future<LuaLib?> getByLibName(String libName);

  @Query("select * from LuaLib")
  Future<List<LuaLib>> getAllLibs();
}
