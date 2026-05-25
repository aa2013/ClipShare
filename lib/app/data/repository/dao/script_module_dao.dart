import 'package:clipshare/app/data/repository/entity/tables/script_module.dart';
import 'package:floor/floor.dart';

@dao
abstract class ScriptModuleDao {
  @insert
  Future<int> addModule(ScriptModule module);

  @update
  Future<int> updateModule(ScriptModule module);

  @Query("delete from ScriptModule where moduleName = :name")
  Future<int?> remove(String name);

  @Query("select * from ScriptModule where moduleName = :name")
  Future<ScriptModule?> getByName(String name);

  @Query("select * from ScriptModule")
  Future<List<ScriptModule>> getAllModules();
}
