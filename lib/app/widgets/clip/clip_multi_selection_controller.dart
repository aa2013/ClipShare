import 'dart:collection';

import 'package:clipshare/app/data/models/clip_data.dart';

/// 剪贴板多选控制器。
///
/// 统一维护多选模式、选中集合以及区间补选逻辑，
/// 让主窗体和历史弹窗可以共享同一套选择语义。
class ClipMultiSelectionController {
  bool _enabled = false;

  /// 多选项需要同时去重并保留加入顺序，合并复制会按该迭代顺序拼接内容。
  final LinkedHashSet<ClipData> _selectedItems = LinkedHashSet<ClipData>();

  bool get enabled => _enabled;

  Set<ClipData> get selectedItems => _selectedItems;

  int get selectedCount => _selectedItems.length;

  bool get canMergeCopy => _enabled && _selectedItems.length > 1;

  /// 按当前选中顺序拼接内容，保持与主窗体既有合并复制行为一致。
  String get mergedContent {
    return _selectedItems.map((item) => item.data.content).join('\n');
  }

  bool contains(ClipData item) {
    return _selectedItems.contains(item);
  }

  /// 开启多选模式；若已经开启则保持现状，避免重复重置用户选择。
  void enable() {
    _enabled = true;
  }

  /// 清空选择并退出多选模式，供 Esc、FAB 关闭等统一复用。
  void clearAndExit() {
    _selectedItems.clear();
    _enabled = false;
  }

  /// 切换单条选择状态；仅在多选模式下生效。
  void toggleItem(ClipData item) {
    if (!_enabled) {
      return;
    }
    if (_selectedItems.contains(item)) {
      _selectedItems.remove(item);
    } else {
      _selectedItems.add(item);
    }
  }

  /// 沿用主窗体现有区间补选算法，不引入新的 Shift/Ctrl 语义。
  void selectRange(List<ClipData> items, ClipData item) {
    if (!_enabled) {
      return;
    }
    if (_selectedItems.isEmpty || _selectedItems.contains(item)) {
      toggleItem(item);
      return;
    }
    var reverse = false;
    var start = -1;
    var end = -1;
    for (var i = 0; i < items.length; i++) {
      if (!reverse && items[i] == item && start == -1) {
        reverse = true;
      }
      if (reverse) {
        if (items[i] == item) {
          start = i;
        } else if (_selectedItems.contains(items[i])) {
          end = i;
        }
      } else {
        if (_selectedItems.contains(items[i]) && start == -1) {
          start = i;
        }
        if (items[i] == item && start != -1) {
          end = i;
          break;
        }
      }
    }
    if (start < 0 || end < 0) {
      _selectedItems.add(item);
      return;
    }
    for (var i = start; i <= end; i++) {
      _selectedItems.add(items[i]);
    }
  }

  /// 列表刷新或删除后，移除已经不存在的数据，避免选中态指向失效项。
  void removeMissingItems(Iterable<ClipData> availableItems) {
    final availableSet = availableItems.toSet();
    _selectedItems.removeWhere((item) => !availableSet.contains(item));
  }
}
