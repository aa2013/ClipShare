import 'package:clipshare/app/data/models/statistics/history_tag_cnt.dart';
import 'package:clipshare/app/data/repository/entity/tables/history_tag.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:floor/floor.dart';
import 'package:get/get.dart';

import '../entity/views/v_history_tag_hold.dart';

@dao
abstract class HistoryTagDao {
  final dbService = Get.find<DbService>();

  ///获取所有标签名
  @Query("select distinct tagName from HistoryTag order by tagName")
  Future<List<String>> getAllTagNames();

  ///查询某个记录的标签列表
  @Query("select * from HistoryTag where hisId = :hId")
  Future<List<HistoryTag>> list(int hId);

  ///查询所有标签列表
  @Query("select * from HistoryTag")
  Future<List<HistoryTag>> getAll();

  ///查询所有标签，返回值含有一个该历史 id 是否持有该标签的标记
  @Query("SELECT * from VHistoryTagHold where hisId = :hId")
  Future<List<VHistoryTagHold>> listWithHold(int hId);

  ///插入一条标签
  @Insert(onConflict: OnConflictStrategy.ignore)
  Future<int> add(HistoryTag tag);

  ///删除标签
  @Query("delete from HistoryTag where hisId = :hId and tagName = :tagName ")
  Future<int?> remove(int hId, String tagName);

  ///删除标签
  @Query("delete from HistoryTag where id = :id")
  Future<int?> removeById(int id);

  ///删除指定历史的所有标签
  @Query("delete from HistoryTag where hisId = :hId")
  Future<int?> removeAllByHisId(int hId);

  ///获取指定历史的所有标签
  @Query("select * from HistoryTag where hisId = :hId")
  Future<List<HistoryTag>> getAllByHisId(int hId);

  ///删除指定历史的所有标签
  @Query("delete from HistoryTag where hisId in (:hIds)")
  Future<int?> deleteByHisIds(List<int> hIds);

  ///删除所有标签
  @Query("delete from HistoryTag")
  Future<int?> removeAll();

  ///获取标签
  @Query("select * from HistoryTag where hisId = :hId and tagName = :tagName ")
  Future<HistoryTag?> get(int hId, String tagName);

  ///获取标签
  @Query("select * from HistoryTag where id = :id")
  Future<HistoryTag?> getById(int id);

  @update
  Future<int> updateTag(HistoryTag tag);

  ///查询各个标签的引用数量
  Future<List<HistoryTagCnt>> getHistoryTagCnt(
    int uid,
    String startMonth,
    String endMonth,
  ) async {
    const sql = """
    select
     tagName,
     count(1) as cnt
    from HistoryTag ht
    join History h
    on h.id = ht.hisId and h.uid = ?1
    and strftime('%Y-%m', time) between ?2 and ?3
    group by tagName
    """;
    List<Map<String, Object?>> result = await dbService.dbExecutor.rawQuery(
      sql,
      [uid, startMonth, endMonth],
    );
    return result
        .map(
          (item) => HistoryTagCnt(
            cnt: item['cnt'] as int,
            tagName: item['tagName'] as String,
          ),
        )
        .toList();
  }
}
