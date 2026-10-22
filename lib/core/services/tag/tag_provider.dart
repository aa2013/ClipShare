import 'package:clipshare/core/database/app_database.dart';
import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/database/dao/history_tag_dao.dart';
import 'package:clipshare/core/database/dao/operation_record_dao.dart';
import 'package:clipshare/core/database/tables/operation_record.dart';
import 'package:clipshare/core/runtime/snowflake/id_provider.dart';
import 'package:clipshare/core/services/device/local_device_info.dart';
import 'package:clipshare/core/services/device/local_device_info_provider.dart';
import 'package:clipshare/core/services/transport/message_sync/sync_push_provider.dart';
import 'package:clipshare/shared/models/module.dart';
import 'package:clipshare/shared/models/op_method.dart';
import 'package:clipshare/shared/utils/snowflake.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tag_provider.g.dart';

/// 标签状态模型
@immutable
class TagState {
  /// hisId -> 该历史记录的全部标签名
  final Map<int, Set<String>> _tagsByHisId;

  /// tagName -> 引用计数（被多少条历史记录使用）
  final Map<String, int> _tagNameCount;

  const TagState({
    required Map<int, Set<String>> tagsByHisId,
    required Map<String, int> tagNameCount,
  })  : _tagsByHisId = tagsByHisId,
        _tagNameCount = tagNameCount;

  /// 获取指定历史记录的全部标签名（无则返回空集合）
  Set<String> getTagList(int hisId) => _tagsByHisId[hisId] ?? const <String>{};

  /// 判断某个标签名是否仍被任意历史记录使用（计数为 0 表示已无引用，可清理）
  bool containsTag(String tagName) => (_tagNameCount[tagName] ?? 0) > 0;

  List<String> get list => _tagsByHisId.values.flattenedToSet.toList();

}

@Riverpod(keepAlive: true)
class TagNotifier extends _$TagNotifier {
  Snowflake get _snowflake => ref.read(idProvider);

  BaseDeviceInfo get _baseDevInfo => ref.read(localDeviceInfoProvider).requireValue.baseDeviceInfo;

  HistoryTagDao get _historyTagDao => ref.read(appDbProvider).requireValue.historyTagDao;

  OperationRecordDao get _opRecordDao => ref.read(appDbProvider).requireValue.operationRecordDao;

  SyncPushNotifier get _syncPushNotifier => ref.read(syncPushProvider.notifier);

  /// 当前标签数据基准（state 尚未就绪时返回空数据）
  TagState get _current =>
      state.value ??
      const TagState(tagsByHisId: <int, Set<String>>{}, tagNameCount: <String, int>{});

  @override
  Future<TagState> build() async {
    final lst = await _historyTagDao.getAll();
    final tagsByHisId = <int, Set<String>>{};
    final tagNameCount = <String, int>{};
    for (var tag in lst) {
      tagsByHisId.putIfAbsent(tag.hisId, () => <String>{}).add(tag.tagName);
      tagNameCount[tag.tagName] = (tagNameCount[tag.tagName] ?? 0) + 1;
    }
    return TagState(tagsByHisId: tagsByHisId, tagNameCount: tagNameCount);
  }

  Future<void> _remove(HistoryTag tag, {required bool notifyPeers}) async {
    await _historyTagDao.removeById(tag.id);

    final current = _current;
    final tags = current._tagsByHisId;
    // 移除标签映射，空集合时移除整个 hisId 键
    final set = tags[tag.hisId];
    if (set != null) {
      if (set.length == 1) {
        tags.remove(tag.hisId);
      } else {
        set.remove(tag.tagName);
      }
    }

    // 更新引用计数，计数为 0 时移除该标签键
    final countMap = current._tagNameCount;
    if ((countMap[tag.tagName] ?? 0) == 1) {
      countMap.remove(tag.tagName);
    } else if ((countMap[tag.tagName] ?? 0) > 1) {
      countMap[tag.tagName] = countMap[tag.tagName]! - 1;
    }

    if (notifyPeers) {
      final opRecord = newOperationRecord(
        _snowflake,
        _baseDevInfo,
        Module.tag,
        OpMethod.delete,
        tag.id.toString(),
      );
      // 添加操作记录
      await _opRecordDao.add(opRecord);
      await _syncPushNotifier.pushRecord(opRecord);
    }
    state = AsyncData(TagState(tagsByHisId: tags, tagNameCount: countMap));
  }

  /// 应用标签新增；[notifyPeers] 为 false 时不生成并推送操作记录。
  Future<bool> _add(HistoryTag tag, {required bool notifyPeers}) async {
    final current = _current;
    final existed = current.getTagList(tag.hisId).contains(tag.tagName);
    // 本机重复新增时 不落库、不推送
    if (notifyPeers && existed) {
      return false;
    }

    final inserted = await _historyTagDao.add(tag) > 0;
    // 唯一索引冲突时插入返回 0，但记录可能已存在，仍视为成功
    final persisted = inserted || await _historyTagDao.get(tag.hisId, tag.tagName) != null;
    if (!persisted) {
      return false;
    }
    // 远端重复新增忽略
    if (existed) {
      return true;
    }

    // 更新标签映射与引用计数
    current._tagsByHisId.putIfAbsent(tag.hisId, () => <String>{}).add(tag.tagName);
    final countMap = current._tagNameCount;
    countMap[tag.tagName] = (countMap[tag.tagName] ?? 0) + 1;

    if (notifyPeers) {
      final opRecord = newOperationRecord(
        _snowflake,
        _baseDevInfo,
        Module.tag,
        OpMethod.add,
        tag.id.toString(),
      );
      // 添加操作记录
      await _opRecordDao.add(opRecord);
      await _syncPushNotifier.pushRecord(opRecord);
    }

    state = AsyncData(TagState(
      tagsByHisId: current._tagsByHisId,
      tagNameCount: current._tagNameCount,
    ));
    return true;
  }

  ///添加
  Future<bool> add(HistoryTag tag) async {
    return _add(tag, notifyPeers: true);
  }

  ///批量添加
  Future<void> addList(Iterable<HistoryTag> tags) async {
    for (var tag in tags) {
      await _add(tag, notifyPeers: true);
    }
  }

  ///删除 tag
  Future<void> remove(HistoryTag tag) async {
    await _remove(tag, notifyPeers: true);
  }

  ///批量删除
  Future<void> removeList(Iterable<HistoryTag> tags) async {
    for (var tag in tags) {
      await _remove(tag, notifyPeers: true);
    }
  }

  /// 应用远端新增的标签，不生成、不推送操作记录。
  Future<bool> applyRemoteAdd(HistoryTag tag) {
    return _add(tag, notifyPeers: false);
  }

  /// 应用远端删除的标签，不生成、不推送操作记录。
  Future<bool> applyRemoteRemove(HistoryTag tag) async {
    final local = await _historyTagDao.getById(tag.id);
    if (local == null) {
      return true;
    }
    await _remove(local, notifyPeers: false);
    return true;
  }
}
