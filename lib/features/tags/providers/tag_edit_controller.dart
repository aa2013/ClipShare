import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/database/tables/history_tag.dart';
import 'package:clipshare/core/database/views/v_history_tag_hold.dart';
import 'package:clipshare/core/snowflake/id_provider.dart';
import 'package:clipshare/core/tag/tag_provider.dart';
import 'package:clipshare/shared/extensions/string_extension.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tag_edit_controller.g.dart';

const _tag = 'TagEditController';

/// 标签编辑状态。
///
/// [tags] 为全量标签（携带加载时的原始标记），[selected] 为用户当前选中集合，
/// [originalSelected] 记录加载时的选中快照，保存时据此计算增删差集。
@immutable
class TagEditState {
  final List<VHistoryTagHold> tags;
  final Set<String> selected;
  final Set<String> originalSelected;
  final String keyword;
  final bool saving;

  const TagEditState({
    this.tags = const [],
    this.selected = const <String>{},
    this.originalSelected = const <String>{},
    this.keyword = '',
    this.saving = false,
  });

  TagEditState copyWith({
    List<VHistoryTagHold>? tags,
    Set<String>? selected,
    Set<String>? originalSelected,
    String? keyword,
    bool? saving,
  }) {
    return TagEditState(
      tags: tags ?? this.tags,
      selected: selected ?? this.selected,
      originalSelected: originalSelected ?? this.originalSelected,
      keyword: keyword ?? this.keyword,
      saving: saving ?? this.saving,
    );
  }

  /// 按关键字过滤后的可见标签，保持首屏加载顺序
  List<VHistoryTagHold> get visibleTags {
    return tags
        .where((t) => keyword.isEmpty || t.tagName.containsIgnoreCase(keyword))
        .toList(growable: false);
  }

  /// 当前输入是否已存在于标签列表，用于决定是否展示“创建标签”入口。
  bool get tagExists => tags.any((t) => t.tagName == keyword);

  bool isSelected(String tagName) => selected.contains(tagName);
}

/// 标签编辑控制器，按历史记录 id 独立维护编辑态。
///
/// 采用 autoDispose：弹窗关闭或页面退出后自动销毁，下次打开天然重置。
@riverpod
class TagEditController extends _$TagEditController {
  @override
  Future<TagEditState> build(int hisId) async {
    final dao = (await ref.read(appDbProvider.future)).historyTagDao;
    final holds = await dao.listWithHold(hisId);
    final selected = holds.where((h) => h.hasTag).map((h) => h.tagName).toSet();
    return TagEditState(
      tags: holds,
      selected: selected,
      originalSelected: Set.of(selected),
    );
  }

  void updateKeyword(String keyword) {
    final current = state.value;
    if (current == null || current.saving) {
      return;
    }
    state = AsyncData(current.copyWith(keyword: keyword));
  }

  /// 切换某个标签的选中状态。
  void toggleTag(String tagName, bool selected) {
    final current = state.value;
    if (current == null || current.saving) {
      return;
    }
    final next = Set<String>.of(current.selected);
    if (selected) {
      next.add(tagName);
    } else {
      next.remove(tagName);
    }
    state = AsyncData(current.copyWith(selected: next));
  }

  /// 创建并选中一个新标签，已存在同名标签时忽略。
  void createTag(String tagName) {
    final current = state.value;
    if (current == null || current.saving || tagName.isEmpty) {
      return;
    }
    if (current.tags.any((t) => t.tagName == tagName)) {
      return;
    }
    state = AsyncData(
      current.copyWith(
        tags: [...current.tags, VHistoryTagHold(hisId, tagName, true)],
        selected: Set<String>.of(current.selected)..add(tagName),
        keyword: '',
      ),
    );
  }

  /// 保存编辑结果：按差集删除/新增标签，复用 [tagProvider] 同步状态与操作记录。
  Future<bool> save() async {
    final current = state.value;
    if (current == null || current.saving) {
      return false;
    }
    state = AsyncData(current.copyWith(saving: true));
    try {
      final dao = (await ref.read(appDbProvider.future)).historyTagDao;
      final willRemove = current.originalSelected.difference(current.selected);
      final willAdd = current.selected.difference(current.originalSelected);

      final removeList = <HistoryTag>[];
      for (final tagName in willRemove) {
        final tag = await dao.get(hisId, tagName);
        if (tag != null) {
          removeList.add(tag);
        }
      }
      final idGenerator = ref.read(idProvider);
      final addList = [
        for (final tagName in willAdd) newHistoryTag(idGenerator.nextId(), tagName, hisId),
      ];

      final tagNotifier = ref.read(tagProvider.notifier);
      await tagNotifier.removeList(removeList);
      await tagNotifier.addList(addList);

      final latest = state.value;
      if (latest != null) {
        state = AsyncData(
          latest.copyWith(saving: false, originalSelected: Set.of(latest.selected)),
        );
      }
      return true;
    } catch (err, stack) {
      logger.error(_tag, err, stack);
      final latest = state.value;
      if (latest != null) {
        state = AsyncData(latest.copyWith(saving: false));
      }
      return false;
    }
  }
}
