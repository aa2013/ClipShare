import 'package:clipshare/app/data/repository/entity/tables/app_info.dart';
import 'package:floor/floor.dart';

@dao
abstract class AppInfoDao {
  @Query("select * from AppInfo")
  Future<List<AppInfo>> getAllAppInfos();

  @Query("select * from AppInfo where id = :id")
  Future<AppInfo?> getById(int id);

  ///通过唯一索引获取
  @Query("select * from AppInfo where appId = :appId and devId = :devId")
  Future<AppInfo?> getByUniqueIndex(String devId, String appId);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<int> addAppInfo(AppInfo appInfo);

  @update
  Future<int> updateAppInfo(AppInfo appInfo);

  @delete
  Future<int> remove(AppInfo appInfo);

  @Query("""
  delete from AppInfo
  where not exists (
      select 1 from History as his where his.devId = AppInfo.devId and his.source = AppInfo.appId
  )
  """)
  Future<int?> removeNotUsed();

}
