import 'package:clipshare/app/data/repository/entity/tables/app_info.dart';
import 'package:floor/floor.dart';

@dao
abstract class AppInfoDao {
  @Query("select * from AppInfo")
  Future<List<AppInfo>> getAllAppInfos();

  @Query("select * from AppInfo where id = :id")
  Future<AppInfo?> getById(int id);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<int> addAppInfo(AppInfo appInfo);

  @update
  Future<int> updateAppInfo(AppInfo appInfo);

  @delete
  Future<int> remove(AppInfo appInfo);

  @Query("""
  delete from AppInfo as app
  where not exists (
      select 1 from History as his where his.devId=app.devId and his.source=app.appId
  )
  """)
  Future<int?> removeNotUsed();

}
