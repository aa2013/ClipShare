import 'package:clipshare/core/database/app_database.dart';
import 'package:clipshare/core/database/app_tables.dart';
import 'package:drift/drift.dart';

part 'app_info_dao.g.dart';

@DriftAccessor(tables: [AppInfos, Histories])
class AppInfoDao extends DatabaseAccessor<AppDatabase> with _$AppInfoDaoMixin {
  AppInfoDao(super.attachedDatabase);

  /// 获取全部应用来源信息。
  Future<List<AppInfo>> getAllAppInfos() {
    return select(appInfos).get();
  }

  /// 通过雪花主键查询应用来源信息。
  Future<AppInfo?> getById(int id) {
    return (select(appInfos)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  /// 通过 appId + devId 唯一索引查询来源信息。
  Future<AppInfo?> getByUniqueIndex(String devId, String appId) {
    return (select(appInfos)..where((tbl) => tbl.devId.equals(devId) & tbl.appId.equals(appId))).getSingleOrNull();
  }

  /// 插入或替换应用来源信息，兼容既有 replace 写入策略。
  Future<int> addAppInfo(AppInfo appInfo) {
    return into(appInfos).insertOnConflictUpdate(_companion(appInfo));
  }

  /// 更新应用来源信息。
  Future<int> updateAppInfo(AppInfo appInfo) {
    return (update(appInfos)..where((tbl) => tbl.id.equals(appInfo.id))).write(_companion(appInfo));
  }

  /// 删除指定应用来源信息。
  Future<int> remove(AppInfo appInfo) {
    return (delete(appInfos)..where((tbl) => tbl.id.equals(appInfo.id))).go();
  }

  /// 清理没有任何历史记录引用的应用来源。
  Future<int?> removeNotUsed() {
    final usedSource = selectOnly(histories)
      ..addColumns([histories.id])
      ..where(histories.devId.equalsExp(appInfos.devId) & histories.source.equalsExp(appInfos.appId));
    return (delete(appInfos)..where((tbl) => notExistsQuery(usedSource))).go();
  }

  /// 将领域对象转换为 Drift 写入对象，集中维护旧字段名映射。
  AppInfosCompanion _companion(AppInfo appInfo) {
    return AppInfosCompanion.insert(
      id: Value(appInfo.id),
      appId: appInfo.appId,
      devId: appInfo.devId,
      name: appInfo.name,
      iconB64: appInfo.iconB64,
    );
  }
}
