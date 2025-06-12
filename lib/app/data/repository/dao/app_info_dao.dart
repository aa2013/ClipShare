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
}
