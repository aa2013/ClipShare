import 'package:clipshare/app/data/repository/db/app_database.dart';
import 'package:clipshare/app/data/repository/db/app_tables.dart';
import 'package:clipshare/app/data/repository/entity/tables/script_module.dart';
import 'package:drift/drift.dart';

part 'script_module_dao.g.dart';

@DriftAccessor(tables: [ScriptModules])
class ScriptModuleDao extends DatabaseAccessor<AppDatabase> with _$ScriptModuleDaoMixin {
  ScriptModuleDao(super.attachedDatabase);

  /// 添加脚本库模块。
  Future<int> addModule(ScriptModule module) {
    return into(scriptModules).insert(_companion(module));
  }

  /// 更新脚本库模块。
  Future<int> updateModule(ScriptModule module) {
    return (update(scriptModules)..where((tbl) => tbl.moduleName.equals(module.moduleName))).write(_companion(module));
  }

  /// 按模块名删除脚本库模块。
  Future<int?> remove(String name) {
    return (delete(scriptModules)..where((tbl) => tbl.moduleName.equals(name))).go();
  }

  /// 按模块名查询脚本库模块。
  Future<ScriptModule?> getByName(String name) {
    return (select(scriptModules)..where((tbl) => tbl.moduleName.equals(name))).getSingleOrNull();
  }

  /// 获取全部脚本库模块。
  Future<List<ScriptModule>> getAllModules() {
    return select(scriptModules).get();
  }

  /// 将脚本库领域对象转换为 Drift 写入对象，忽略仅 UI 使用的 isNewData。
  ScriptModulesCompanion _companion(ScriptModule module) {
    return ScriptModulesCompanion.insert(
      moduleName: module.moduleName,
      displayName: module.displayName,
      language: module.language,
      source: module.source,
      version: module.version,
    );
  }
}
