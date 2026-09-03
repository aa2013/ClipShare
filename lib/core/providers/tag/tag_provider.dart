import 'package:clipshare/core/database/app_database.dart';
import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/database/dao/history_tag_dao.dart';
import 'package:clipshare/core/database/dao/operation_record_dao.dart';
import 'package:clipshare/core/database/tables/operation_record.dart';
import 'package:clipshare/core/providers/device/local_device_info.dart';
import 'package:clipshare/core/providers/local_device/local_device_info_provider.dart';
import 'package:clipshare/core/providers/snowflake/id_provider.dart';
import 'package:clipshare/core/utils/snowflake.dart';
import 'package:clipshare/shared/models/module.dart';
import 'package:clipshare/shared/models/op_method.dart';
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

  Future<void> _remove(HistoryTag tag, [bool notify = true]) async {
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

    var opRecord = newOperationRecord(
      _snowflake,
      _baseDevInfo,
      Module.tag,
      OpMethod.delete,
      tag.id.toString(),
    );
    //添加操作记录
    await _opRecordDao.addAndNotify(opRecord);

    // 更新引用计数，计数为 0 时移除该标签键
    final countMap = current._tagNameCount;
    if ((countMap[tag.tagName] ?? 0) == 1) {
      countMap.remove(tag.tagName);
    } else if ((countMap[tag.tagName] ?? 0) > 1) {
      countMap[tag.tagName] = countMap[tag.tagName]! - 1;
    }

    // 构造新的 TagState 实例（identity 变化），通知所有 watch 方刷新
    state = AsyncData(TagState(tagsByHisId: tags, tagNameCount: countMap));
  }

  Future<bool> _add(HistoryTag tag, [bool notify = true]) async {
    final current = _current;
    // 已存在相同标签则直接返回
    if (current.getTagList(tag.hisId).contains(tag.tagName)) {
      return false;
    }

    var res = false;
    if (notify) {
      res = await _historyTagDao.add(tag) > 0;
      if (!res) {
        return false;
      }
      var opRecord = newOperationRecord(
        _snowflake,
        _baseDevInfo,
        Module.tag,
        OpMethod.add,
        tag.id.toString(),
      );
      //添加操作记录
      await _opRecordDao.addAndNotify(opRecord);
      // 写库成功才更新引用计数
      final countMap = current._tagNameCount;
      countMap[tag.tagName] = (countMap[tag.tagName] ?? 0) + 1;
    }

    // 更新标签映射（notify=true 成功，或 notify=false 仅内存更新）
    current._tagsByHisId.putIfAbsent(tag.hisId, () => <String>{}).add(tag.tagName);

    // 构造新的 TagState 实例（identity 变化），通知所有 watch 方刷新
    state = AsyncData(TagState(
      tagsByHisId: current._tagsByHisId,
      tagNameCount: current._tagNameCount,
    ));
    return res;
  }

  ///添加
  Future<bool> add(HistoryTag tag, [bool notify = true]) async {
    return await _add(tag, notify);
  }

  ///批量添加
  Future<void> addList(Iterable<HistoryTag> tags, [bool notify = true]) async {
    for (var tag in tags) {
      await _add(tag, notify);
    }
  }

  ///删除 tag
  Future<void> remove(HistoryTag tag, [bool notify = true]) async {
    await _remove(tag, notify);
  }

  ///批量删除
  Future<void> removeList(
    Iterable<HistoryTag> tags, [
    bool notify = true,
  ]) async {
    for (var tag in tags) {
      await _remove(tag, notify);
    }
  }
}
