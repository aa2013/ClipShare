import 'dart:collection';

import 'package:clipshare/core/database/tables/history.dart';

/// 统一维护多选模式、选中集合与区间补选逻辑。
///
/// 选中集合使用 LinkedHashSet，既去重又保留加入顺序。
class HistoryMultiSelectionController {
  bool _enabled = false;
  final LinkedHashSet<History> _selectedItems = LinkedHashSet<History>();

  bool get enabled => _enabled;

  Set<History> get selectedItems => _selectedItems;

  int get selectedCount => _selectedItems.length;

  bool get canMergeCopy => _enabled && _selectedItems.length > 1;

  String get mergedContent => _selectedItems.map((item) => item.content).join('\n');

  bool contains(History item) => _selectedItems.contains(item);

  void enable() {
    _enabled = true;
  }

  void clearAndExit() {
    _selectedItems.clear();
    _enabled = false;
  }

  void toggleItem(History item) {
    if (!_enabled) {
      return;
    }
    if (_selectedItems.contains(item)) {
      _selectedItems.remove(item);
    } else {
      _selectedItems.add(item);
    }
  }

  /// 在目标项与最近选中项之间补齐整段区间。
  void selectRange(List<History> items, History item) {
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

  /// 移除列表中已不存在的选中项，避免选中态指向失效记录。
  void removeMissingItems(Iterable<History> availableItems) {
    final availableSet = availableItems.toSet();
    _selectedItems.removeWhere((item) => !availableSet.contains(item));
  }

}
