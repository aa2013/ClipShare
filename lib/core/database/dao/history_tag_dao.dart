import 'package:clipshare/core/database/app_database.dart' hide VHistoryTagHold;
import 'package:clipshare/core/database/app_tables.dart';
import 'package:clipshare/core/database/views/v_history_tag_hold.dart';
import 'package:clipshare/shared/models/statistics/history_tag_cnt.dart';
import 'package:drift/drift.dart';

part 'history_tag_dao.g.dart';

@DriftAccessor(tables: [HistoryTags, Histories])
class HistoryTagDao extends DatabaseAccessor<AppDatabase> with _$HistoryTagDaoMixin {
  HistoryTagDao(super.attachedDatabase);

  /// 获取所有标签名，按名称升序去重。
  Future<List<String>> getAllTagNames() async {
    final query = selectOnly(historyTags, distinct: true)
      ..addColumns([historyTags.tagName])
      ..orderBy([OrderingTerm.asc(historyTags.tagName)]);
    final rows = await query.get();
    return rows.map((row) => row.read<String>(historyTags.tagName)).whereType<String>().toList();
  }

  /// 查询某个历史记录的标签列表。
  Future<List<HistoryTag>> list(int hId) {
    return (select(historyTags)..where((tbl) => tbl.hisId.equals(hId))).get();
  }

  /// 查询所有标签列表。
  Future<List<HistoryTag>> getAll() {
    return select(historyTags).get();
  }

  /// 查询所有标签，并标记指定历史记录是否持有该标签。
  Future<List<VHistoryTagHold>> listWithHold(int hId) async {
    final rows = await customSelect(
      'SELECT * FROM $vHistoryTagHoldViewName WHERE hisId = ?',
      variables: [Variable.withInt(hId)],
      readsFrom: {historyTags, histories},
    ).get();
    final result = rows.map((row) {
      final rawHasTag = row.data['hasTag'];
      return VHistoryTagHold(
        row.read<int>('hisId'),
        row.read<String>('tagName'),
        rawHasTag == true || rawHasTag == 1,
      );
    }).toList();
    result.sort();
    return result;
  }

  /// 插入一条标签，唯一索引冲突时忽略。
  Future<int> add(HistoryTag tag) {
    return into(historyTags).insert(
      HistoryTagsCompanion.insert(
        id: Value(tag.id),
        tagName: tag.tagName,
        hisId: tag.hisId,
      ),
      mode: InsertMode.insertOrIgnore,
    );
  }

  /// 删除指定历史记录上的单个标签。
  Future<int?> remove(int hId, String tagName) {
    return (delete(historyTags)..where((tbl) => tbl.hisId.equals(hId) & tbl.tagName.equals(tagName))).go();
  }

  /// 按标签主键删除标签。
  Future<int?> removeById(int id) {
    return (delete(historyTags)..where((tbl) => tbl.id.equals(id))).go();
  }

  /// 删除指定历史记录的所有标签。
  Future<int?> removeAllByHisId(int hId) {
    return (delete(historyTags)..where((tbl) => tbl.hisId.equals(hId))).go();
  }

  /// 获取指定历史记录的所有标签。
  Future<List<HistoryTag>> getAllByHisId(int hId) {
    return (select(historyTags)..where((tbl) => tbl.hisId.equals(hId))).get();
  }

  /// 删除多个历史记录的所有标签。
  Future<int?> deleteByHisIds(List<int> hIds) {
    if (hIds.isEmpty) return Future.value(0);
    return (delete(historyTags)..where((tbl) => tbl.hisId.isIn(hIds))).go();
  }

  /// 删除所有标签。
  Future<int?> removeAll() {
    return delete(historyTags).go();
  }

  /// 根据历史 id 和标签名获取标签。
  Future<HistoryTag?> get(int hId, String tagName) {
    return (select(historyTags)..where((tbl) => tbl.hisId.equals(hId) & tbl.tagName.equals(tagName))).getSingleOrNull();
  }

  /// 根据主键获取标签。
  Future<HistoryTag?> getById(int id) {
    return (select(historyTags)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  /// 更新标签内容，按主键定位。
  Future<int> updateTag(HistoryTag tag) {
    return (update(historyTags)..where((tbl) => tbl.id.equals(tag.id))).write(
      HistoryTagsCompanion(
        tagName: Value(tag.tagName),
        hisId: Value(tag.hisId),
      ),
    );
  }

  /// 查询各个标签的引用数量，月份聚合依赖 SQLite strftime。
  Future<List<HistoryTagCnt>> getHistoryTagCnt(int uid, String startMonth, String endMonth) async {
    final result = await customSelect(
      '''
      select tagName, count(1) as cnt
      from HistoryTag ht
      join History h
      on h.id = ht.hisId and h.uid = ?1
      and strftime('%Y-%m', time) between ?2 and ?3
      group by tagName
      ''',
      variables: [
        Variable.withInt(uid),
        Variable.withString(startMonth),
        Variable.withString(endMonth),
      ],
      readsFrom: {historyTags, histories},
    ).get();
    return result
        .map(
          (item) => HistoryTagCnt(
            cnt: item.read<int>('cnt'),
            tagName: item.read<String>('tagName'),
          ),
        )
        .toList();
  }
}
