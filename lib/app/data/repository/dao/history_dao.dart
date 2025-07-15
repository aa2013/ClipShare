import 'package:clipshare/app/data/enums/module.dart';
import 'package:clipshare/app/data/enums/op_method.dart';
import 'package:clipshare/app/data/models/search_filter.dart';
import 'package:clipshare/app/data/models/statistics/history_cnt_for_device.dart';
import 'package:clipshare/app/data/models/statistics/history_type_cnt.dart';
import 'package:clipshare/app/data/repository/entity/tables/operation_record.dart';
import 'package:clipshare/app/services/clipboard_source_service.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:floor/floor.dart';
import 'package:get/get.dart';

import '../entity/tables/history.dart';

@dao
abstract class HistoryDao {
  final dbService = Get.find<DbService>();
  final appConfig = Get.find<ConfigService>();

  ///获取最新记录
  @Query("select * from history where uid = :uid order by id desc limit 1")
  Future<History?> getLatestLocalClip(int uid);

  /// 根据条件查询，一次查 100 条，置顶优先，id 降序
  @Query("""
  SELECT * FROM History
  WHERE uid = :uid
    AND (:fromId = 0 OR id < :fromId)
    AND (:content = '' OR content LIKE '%' || :content || '%')
    AND (:type = '' OR type = :type)
    AND (:startTime = '' OR :endTime = '' OR date(time) BETWEEN :startTime AND :endTime)
    AND (length(null in (:devIds)) = 1 OR devId IN (:devIds))
    AND (length(null in (:appIds)) = 1 OR source IN (:appIds))
    AND (length(null in (:tags)) = 1 OR id IN (
      SELECT DISTINCT hisId
      FROM HistoryTag
      WHERE tagName IN (:tags)
    ))
    AND (:onlyNoSync = 1 AND sync = 0 OR :onlyNoSync != 1)
  ORDER BY 
    CASE WHEN :ignoreTop = 1 THEN 0 ELSE top END DESC, 
    id DESC
  LIMIT 100
  """)
  Future<List<History>> getHistoriesPageByWhere(
    int uid,
    int fromId,
    String content,
    String type,
    List<String> tags,
    List<String> devIds,
    List<String> appIds,
    String startTime,
    String endTime,
    bool onlyNoSync,
    bool ignoreTop,
  );

  Future<List<History>> getHistoriesPageByFilter(int uid, SearchFilter filter, bool ignoreTop, [int fromId = 0]) {
    return getHistoriesPageByWhere(
      uid,
      fromId,
      filter.content,
      filter.type.value,
      filter.tags.toList(),
      filter.devIds.toList(),
      filter.appIds.toList(),
      filter.startDate,
      filter.endDate,
      filter.onlyNoSync,
      ignoreTop,
    );
  }

  //region 数据清理过滤条件和查询方法
  static const dataCleanFilter = """
    WHERE uid = :uid
    AND (:startTime = '' OR :endTime = '' OR date(time) BETWEEN :startTime AND :endTime)
    AND (:saveTop <> 1 OR top = 0)
    AND (length(null in (:types)) = 1 OR type IN (:types))
    AND (length(null in (:devIds)) = 1 OR devId IN (:devIds))
    AND (length(null in (:appIds)) = 1 OR source IN (:appIds))
    AND (length(null in (:tags)) = 1 OR id IN (
      SELECT DISTINCT hisId
      FROM HistoryTag
      WHERE tagName IN (:tags)
    ))
  """;

  ///根据过滤器统计数量
  @Query("select count(1) from history $dataCleanFilter")
  Future<int?> count(
    int uid,
    List<String> types,
    List<String> tags,
    List<String> devIds,
    List<String> appIds,
    String startTime,
    String endTime,
    bool saveTop,
  );

  ///根据过滤器获取历史数据
  @Query("select * from history $dataCleanFilter")
  Future<List<History>> getHistoriesWithFileContent(
    int uid,
    List<String> types,
    List<String> tags,
    List<String> devIds,
    List<String> appIds,
    String startTime,
    String endTime,
    bool saveTop,
  );

  ///根据设备id统计数量
  Future<int> countByDevId(String devId, int uid) {
    return count(uid, [], [], [devId], [], "", "", false).then((res) => res ?? 0);
  }

  ///更新历史记录来源
  @Query("update history set source = :source where id = :id")
  Future<int?> updateHistorySource(int id, String source);

  ///更新历史记录来源并通知设备
  Future<bool> updateHistorySourceAndNotify(int id, String source) async {
    var cnt = await updateHistorySource(id, source);
    if ((cnt ?? 0) > 0) {
      //更新剪贴板来源
      //先将之前的剪贴板来源操作记录删除再添加操作记录
      await dbService.opRecordDao.deleteHistorySourceRecords(id, Module.historySource.moduleName);
      cnt = await dbService.opRecordDao.addAndNotify(
        OperationRecord.fromSimple(
          Module.historySource,
          OpMethod.update,
          id.toString(),
        ),
      );
      return cnt > 0;
    }
    return false;
  }

  ///清除历史记录来源，调用方记得删除未使用的来源信息
  @Query("update history set source = null where id = :id")
  Future<int?> clearHistorySource(int id);

  ///删除历史记录来源并通知，调用方记得删除未使用的来源信息
  Future<bool> clearHistorySourceAndNotify(int id) async {
    var cnt = await clearHistorySource(id);
    if ((cnt ?? 0) > 0){
      await dbService.opRecordDao.deleteHistorySourceRecords(id, Module.historySource.moduleName);
      cnt = await dbService.opRecordDao.addAndNotify(
        OperationRecord.fromSimple(
          Module.historySource,
          OpMethod.delete,
          id.toString(),
        ),
      );
      return cnt > 0;
    }
    return false;
  }

//endregion

  /// 【废弃】获取某设备未同步的记录
  @Query(
    "SELECT * FROM history h WHERE NOT EXISTS (SELECT 1 FROM SyncHistory sh WHERE sh.hisId = h.id AND sh.devId = :devId) and h.devId != :devId",
  )
  Future<List<History>> getMissingHistory(String devId);

  ///获取前100条历史记录
  @Query("select * from history where uid = :uid order by top desc,id desc limit 100")
  Future<List<History>> getHistoriesTop100(int uid);

  ///获取前100条历史记录
  @Query(
    "select * from history where uid = :uid and id < :fromId order by top desc,id desc limit 100",
  )
  Future<List<History>> getHistoriesPage(int uid, int fromId);

  ///置顶/取消置顶某记录
  @Query("update history set top = :top where id = :id ")
  Future<int?> setTop(int id, bool top);

  ///更新记录同步状态
  @Query("update history set sync = :sync where id = :id ")
  Future<int?> setSync(int id, bool sync);

  ///添加一条历史记录
  @Insert(onConflict: OnConflictStrategy.replace)
  Future<int> add(History history);

  ///将本地记录转换到某个用户
  @Query("update history set uid = :uid where uid = 0")
  Future<int?> transformLocalToUser(int uid);

  ///删除本地记录用户记录
  @Query("delete from history where uid = 0")
  Future<int?> removeAllLocalHistories();

  ///根据id获取记录
  @Query("select * from history where id = :id")
  Future<History?> getById(int id);

  ///获取所有图片
  @Query("select * from history where uid = :uid and type = 'Image' order by id desc")
  Future<List<History>> getAllImages(int uid);

  @update
  Future<int> updateHistory(History history);

  ///获取所有文件
  @Query(
    "select * from history where uid = :uid and type = 'File' order by id desc",
  )
  Future<List<History>> getFiles(int uid);

  ///删除某条记录，调用后记得再移除未使用的剪贴板来源信息
  @Query("delete from history where id = :id")
  Future<int?> delete(int id);

  ///根据 id 删除记录，调用后记得再移除未使用的剪贴板来源信息
  @Query(
    "delete from history where uid = :uid and id in (:ids)",
  )
  Future<int?> deleteByIds(List<int> ids, int uid);

  Future<void> deleteByCascade(int id) async {
    //删除tag
    ((await dbService.historyTagDao.removeAllByHisId(id)) ?? 0) > 0;
    //删除历史
    await dbService.historyDao.delete(id);
    //删除操作记录和同步记录
    await dbService.opRecordDao.deleteByDataWithCascade(id.toString());
    //移除未使用的剪贴板来源信息
    final sourceService = Get.find<ClipboardSourceService>();
    await sourceService.removeNotUsed();
  }

  ///查询历史记录中的不同类型的数量
  Future<List<HistoryTypeCnt>> getHistoryTypeCnt(
    int uid,
    String startMonth,
    String endMonth,
  ) async {
    const sql = """
    select 
      type,
      count(1) cnt,
      strftime('%Y-%m', time) as month
    from History 
    where uid = ?1
    and strftime('%Y-%m', time) between ?2 and ?3
    group by strftime('%Y-%m', time), type
    order by strftime('%Y-%m', time)
    """;
    List<Map<String, Object?>> result = await dbService.dbExecutor.rawQuery(
      sql,
      [uid, startMonth, endMonth],
    );
    return result
        .map(
          (item) => HistoryTypeCnt(
            cnt: item['cnt'] as int,
            type: item['type'] as String,
            date: item['month'] as String,
          ),
        )
        .toList();
  }

  ///查询历史记录中不同设备的历史数量
  Future<List<HistoryCntForDevice>> getHistoryCntForDevice(
    int uid,
    String startMonth,
    String endMonth,
  ) async {
    const sql = """
    select 
      devId,
      (select devName from Device where guid = devId) as devName,
      count(*) as cnt,
      strftime('%Y-%m', time) as month
    from history 
    where uid = ?1
    and strftime('%Y-%m', time) between ?2 and ?3
    group by strftime('%Y-%m', time), devId
    order by strftime('%Y-%m', time)
    """;
    List<Map<String, Object?>> result = await dbService.dbExecutor.rawQuery(
      sql,
      [uid, startMonth, endMonth],
    );
    String selfId = appConfig.device.guid;
    String selfName = appConfig.device.name;
    int unknown = 0;
    return result.map((item) {
      String devName = item['devName']?.toString() ?? 'Unknown${++unknown}';
      String devId = item['devId'].toString();
      return HistoryCntForDevice(
        cnt: item['cnt'] as int,
        devId: devId,
        devName: devId == selfId ? selfName : devName,
        month: item["month"] as String,
      );
    }).toList();
  }
}
