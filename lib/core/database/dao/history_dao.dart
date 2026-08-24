import 'package:clipshare/core/database/app_database.dart';
import 'package:clipshare/core/database/app_tables.dart';
import 'package:clipshare/core/database/tables/operation_record.dart';
import 'package:clipshare/core/utils/snowflake.dart';
import 'package:clipshare/shared/models/local_device_info.dart';
import 'package:clipshare/shared/models/module.dart';
import 'package:clipshare/shared/models/op_method.dart';
import 'package:clipshare/shared/models/search_filter.dart';
import 'package:clipshare/shared/models/statistics/history_cnt_for_device.dart';
import 'package:clipshare/shared/models/statistics/history_type_cnt.dart';
import 'package:drift/drift.dart';

part 'history_dao.g.dart';

@DriftAccessor(tables: [Histories, HistoryTags, Devices])
class HistoryDao extends DatabaseAccessor<AppDatabase> with _$HistoryDaoMixin {
  HistoryDao(super.attachedDatabase);

  /// 获取最新记录。
  Future<History?> getLatestLocalClip(int uid) {
    return (select(histories)
          ..where((tbl) => tbl.uid.equals(uid))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.id)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// 根据条件查询，一次查 100 条，置顶优先，id 降序。
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
  ) {
    final query = select(histories)..where((tbl) => tbl.uid.equals(uid));
    if (fromId > 0) {
      query.where((tbl) => tbl.id.isSmallerThanValue(fromId));
    }
    if (content.isNotEmpty) {
      query.where((tbl) => tbl.content.contains(content));
    }
    if (type.isNotEmpty) {
      query.where((tbl) => tbl.type.equals(type));
    }
    if (startTime.isNotEmpty && endTime.isNotEmpty) {
      query.where(
        (tbl) => tbl.time.isBiggerOrEqualValue('$startTime 00:00:00') & tbl.time.isSmallerOrEqualValue('$endTime 23:59:59.999999'),
      );
    }
    if (devIds.isNotEmpty) {
      query.where((tbl) => tbl.devId.isIn(devIds));
    }
    if (appIds.isNotEmpty) {
      query.where((tbl) => tbl.source.isIn(appIds));
    }
    if (tags.isNotEmpty) {
      final tagQuery = selectOnly(historyTags)
        ..addColumns([historyTags.hisId])
        ..where(historyTags.tagName.isIn(tags));
      query.where((tbl) => tbl.id.isInQuery(tagQuery));
    }
    if (onlyNoSync) {
      query.where((tbl) => tbl.sync.equals(false));
    }
    query
      ..orderBy([
        if (!ignoreTop) (tbl) => OrderingTerm.desc(tbl.top),
        (tbl) => OrderingTerm.desc(tbl.id),
      ])
      ..limit(historyPageSize);
    return query.get();
  }

  /// 根据搜索过滤器分页查询历史。
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

  /// 根据清理过滤器统计数量。
  Future<int?> count(
    int uid,
    List<String> types,
    List<String> tags,
    List<String> devIds,
    List<String> appIds,
    String startTime,
    String endTime,
    bool saveTop,
  ) async {
    final countExp = countAll();
    final query = selectOnly(histories)..addColumns([countExp]);
    query.where(histories.uid.equals(uid));
    if (startTime.isNotEmpty && endTime.isNotEmpty) {
      query.where(histories.time.isBiggerOrEqualValue('$startTime 00:00:00') & histories.time.isSmallerOrEqualValue('$endTime 23:59:59.999999'));
    }
    if (saveTop) {
      query.where(histories.top.equals(false));
    }
    if (types.isNotEmpty) {
      query.where(histories.type.isIn(types));
    }
    if (devIds.isNotEmpty) {
      query.where(histories.devId.isIn(devIds));
    }
    if (appIds.isNotEmpty) {
      query.where(histories.source.isIn(appIds));
    }
    if (tags.isNotEmpty) {
      final tagQuery = selectOnly(historyTags)
        ..addColumns([historyTags.hisId])
        ..where(historyTags.tagName.isIn(tags));
      query.where(histories.id.isInQuery(tagQuery));
    }
    final row = await query.getSingle();
    return row.read<int>(countExp);
  }

  /// 根据清理过滤器获取历史数据。
  Future<List<History>> getHistoriesWithFileContent(
    int uid,
    List<String> types,
    List<String> tags,
    List<String> devIds,
    List<String> appIds,
    String startTime,
    String endTime,
    bool saveTop,
  ) {
    final query = select(histories);
    query.where((tbl) => tbl.uid.equals(uid));
    if (startTime.isNotEmpty && endTime.isNotEmpty) {
      query.where(
        (tbl) => tbl.time.isBiggerOrEqualValue('$startTime 00:00:00') & tbl.time.isSmallerOrEqualValue('$endTime 23:59:59.999999'),
      );
    }
    if (saveTop) {
      query.where((tbl) => tbl.top.equals(false));
    }
    if (types.isNotEmpty) {
      query.where((tbl) => tbl.type.isIn(types));
    }
    if (devIds.isNotEmpty) {
      query.where((tbl) => tbl.devId.isIn(devIds));
    }
    if (appIds.isNotEmpty) {
      query.where((tbl) => tbl.source.isIn(appIds));
    }
    if (tags.isNotEmpty) {
      final tagQuery = selectOnly(historyTags)
        ..addColumns([historyTags.hisId])
        ..where(historyTags.tagName.isIn(tags));
      query.where((tbl) => tbl.id.isInQuery(tagQuery));
    }
    return query.get();
  }

  /// 根据设备 id 统计数量。
  Future<int> countByDevId(String devId, int uid) {
    return count(uid, [], [], [devId], [], '', '', false).then((res) => res ?? 0);
  }

  /// 更新历史记录来源。
  Future<int?> updateHistorySource(int id, String source) {
    return (update(histories)..where((tbl) => tbl.id.equals(id))).write(
      HistoriesCompanion(source: Value(source)),
    );
  }

  /// 更新历史记录来源并通知设备。
  Future<bool> updateHistorySourceAndNotify(
      int id,
      String source,
      Snowflake snowflake,
      BaseDeviceInfo baseDeviceInfo,
  ) async {
    var cnt = await updateHistorySource(id, source);
    if ((cnt ?? 0) > 0) {
      await attachedDatabase.operationRecordDao.deleteHistorySourceRecords(id, Module.historySource.moduleName);
      cnt = await attachedDatabase.operationRecordDao.addAndNotify(
        newOperationRecord(
          snowflake,
          baseDeviceInfo,
          Module.historySource,
          OpMethod.update,
          id.toString(),
        ),
      );
      return cnt > 0;
    }
    return false;
  }

  /// 清除历史记录来源，调用方记得删除未使用的来源信息。
  Future<int?> clearHistorySource(int id) {
    return (update(histories)..where((tbl) => tbl.id.equals(id))).write(
      const HistoriesCompanion(source: Value(null)),
    );
  }

  /// 删除历史记录来源并通知，调用方记得删除未使用的来源信息。
  Future<bool> clearHistorySourceAndNotify(
      int id,
      Snowflake snowflake,
      BaseDeviceInfo baseDeviceInfo,
  ) async {
    var cnt = await clearHistorySource(id);
    if ((cnt ?? 0) > 0) {
      await attachedDatabase.operationRecordDao.deleteHistorySourceRecords(id, Module.historySource.moduleName);
      cnt = await attachedDatabase.operationRecordDao.addAndNotify(
        newOperationRecord(
          snowflake,
          baseDeviceInfo,
          Module.historySource,
          OpMethod.delete,
          id.toString(),
        ),
      );
      return cnt > 0;
    }
    return false;
  }

  /// 获取前 100 条历史记录。
  Future<List<History>> getHistoriesTop100(int uid, List<String> types) {
    final query = select(histories)..where((tbl) => tbl.uid.equals(uid));
    if (types.isNotEmpty) {
      query.where((tbl) => tbl.type.isIn(types));
    }
    query
      ..orderBy([
        (tbl) => OrderingTerm.desc(tbl.top),
        (tbl) => OrderingTerm.desc(tbl.id),
      ])
      ..limit(historyPageSize);
    return query.get();
  }

  /// 分页获取 100 条历史记录。
  Future<List<History>> getHistoriesPage(int uid, int fromId, List<String> types) {
    final query = select(histories)..where((tbl) => tbl.uid.equals(uid));
    if (fromId > 0) {
      query.where((tbl) => tbl.id.isSmallerThanValue(fromId));
    }
    if (types.isNotEmpty) {
      query.where((tbl) => tbl.type.isIn(types));
    }
    query
      ..orderBy([
        (tbl) => OrderingTerm.desc(tbl.top),
        (tbl) => OrderingTerm.desc(tbl.id),
      ])
      ..limit(historyPageSize);
    return query.get();
  }

  /// 置顶或取消置顶某记录。
  Future<int?> setTop(int id, bool top) {
    return (update(histories)..where((tbl) => tbl.id.equals(id))).write(
      HistoriesCompanion(top: Value(top)),
    );
  }

  /// 更新记录同步状态。
  Future<int?> setSync(int id, bool sync) {
    return (update(histories)..where((tbl) => tbl.id.equals(id))).write(
      HistoriesCompanion(sync: Value(sync)),
    );
  }

  /// 添加一条历史记录，按旧雪花 id 主键替换写入。
  Future<int> add(History history) {
    return into(histories).insertOnConflictUpdate(_companion(history));
  }

  /// 将本地记录转换到某个用户。
  Future<int?> transformLocalToUser(int uid) {
    return (update(histories)..where((tbl) => tbl.uid.equals(0))).write(
      HistoriesCompanion(uid: Value(uid)),
    );
  }

  /// 删除本地用户历史记录。
  Future<int?> removeAllLocalHistories() {
    return (delete(histories)..where((tbl) => tbl.uid.equals(0))).go();
  }

  /// 根据 id 获取记录。
  Future<History?> getById(int id) {
    return (select(histories)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  /// 获取所有图片历史。
  Future<List<History>> getAllImages(int uid) {
    return (select(histories)
          ..where((tbl) => tbl.uid.equals(uid) & tbl.type.equals('Image'))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.id)]))
        .get();
  }

  /// 更新历史记录完整内容。
  Future<int> updateHistory(History history) {
    return (update(histories)..where((tbl) => tbl.id.equals(history.id))).write(_companion(history));
  }

  /// 获取所有文件历史。
  Future<List<History>> getFiles(int uid) {
    return (select(histories)
          ..where((tbl) => tbl.uid.equals(uid) & tbl.type.equals('File'))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.id)]))
        .get();
  }

  /// 删除某条历史记录，调用后记得再移除未使用的剪贴板来源信息。
  Future<int?> deleteHistory(int id) {
    return (delete(histories)..where((tbl) => tbl.id.equals(id))).go();
  }

  /// 根据 id 批量删除历史记录。
  Future<int?> deleteByIds(List<int> ids, int uid) {
    if (ids.isEmpty) return Future.value(0);
    return (delete(histories)..where((tbl) => tbl.uid.equals(uid) & tbl.id.isIn(ids))).go();
  }

  /// 级联删除历史、标签、同步记录，并清理未使用的来源信息。
  Future<void> deleteByCascade(int id) async {
    await attachedDatabase.transaction(() async {
      final tags = await attachedDatabase.historyTagDao.getAllByHisId(id);
      final success = ((await attachedDatabase.historyTagDao.removeAllByHisId(id)) ?? 0) > 0;
      if (success && tags.isNotEmpty) {
        final tagIds = tags.map((item) => item.id).toList();
        for (var tagId in tagIds) {
          await attachedDatabase.operationRecordDao.deleteByDataWithCascade(tagId.toString());
        }
      }
      await deleteHistory(id);
      await attachedDatabase.operationRecordDao.deleteByDataWithCascade(id.toString());
    });
    //todo
    // final sourceService = Get.find<ClipboardSourceService>();
    // await sourceService.removeNotUsed();
  }

  /// 查询历史记录中的不同类型数量，月份聚合依赖 SQLite strftime。
  Future<List<HistoryTypeCnt>> getHistoryTypeCnt(int uid, String startMonth, String endMonth) async {
    final result = await customSelect(
      """
      select type, count(1) cnt, strftime('%Y-%m', time) as month
      from History
      where uid = ?1
      and strftime('%Y-%m', time) between ?2 and ?3
      group by strftime('%Y-%m', time), type
      order by strftime('%Y-%m', time)
      """,
      variables: [
        Variable.withInt(uid),
        Variable.withString(startMonth),
        Variable.withString(endMonth),
      ],
      readsFrom: {histories},
    ).get();
    return result
        .map(
          (item) => HistoryTypeCnt(
            cnt: item.read<int>('cnt'),
            type: item.read<String>('type'),
            date: item.read<String>('month'),
          ),
        )
        .toList();
  }

  /// 查询历史记录中不同设备的历史数量，月份聚合依赖 SQLite strftime。
  Future<List<HistoryCntForDevice>> getHistoryCntForDevice(
    int uid,
    String startMonth,
    String endMonth,
    LocalDeviceInfo localDevice,
  ) async {
    final result = await customSelect(
      """
      select
        devId,
        (select ifnull(nullif(customName, ''), devName) from Device where guid = devId) as devName,
        count(*) as cnt,
        strftime('%Y-%m', time) as month
      from history
      where uid = ?1
      and strftime('%Y-%m', time) between ?2 and ?3
      group by strftime('%Y-%m', time), devId
      order by strftime('%Y-%m', time)
      """,
      variables: [
        Variable.withInt(uid),
        Variable.withString(startMonth),
        Variable.withString(endMonth),
      ],
      readsFrom: {histories, devices},
    ).get();
    final selfId = localDevice.baseDeviceInfo.id;
    final selfName = localDevice.localName;
    var unknown = 0;
    return result.map((item) {
      final devName = item.data['devName']?.toString() ?? 'Unknown${++unknown}';
      final devId = item.read<String>('devId');
      return HistoryCntForDevice(
        cnt: item.read<int>('cnt'),
        devId: devId,
        devName: devId == selfId ? selfName : devName,
        month: item.read<String>('month'),
      );
    }).toList();
  }

  /// 将历史领域对象转换为 Drift 写入对象，显式保留旧雪花 id。
  HistoriesCompanion _companion(History history) {
    return HistoriesCompanion.insert(
      id: Value(history.id),
      uid: history.uid,
      time: history.time,
      content: history.content,
      extracted: Value(history.extracted),
      type: history.type,
      devId: history.devId,
      top: history.top,
      sync: history.sync,
      size: history.size,
      updateTime: Value(history.updateTime),
      source: Value(history.source),
    );
  }
}
