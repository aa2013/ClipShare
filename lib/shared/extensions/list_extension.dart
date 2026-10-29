import 'package:collection/collection.dart' as collection;

extension ListExt<T> on List<T> {
  List<List<T>> partition(int size) {
    List<List<T>> result = [];
    for (var i = 0; i < length; i += size) {
      int start = i;
      int end = i + size > length ? length : i + size;
      var subList = sublist(start, end);
      result.add(subList);
    }
    return result;
  }

  /// 将列表按指定键分组（返回 Map<K, List<T>>）
  Map<K, List<T>> groupBy<K>(K Function(T) keySelector) {
    return collection.groupBy(this, keySelector);
  }

  /// 去重
  /// - 不传参数：使用 `==` 进行比较去重
  /// - 传递 function：使用自定义比较逻辑去重（保留首次出现的元素）
  List<T> distinct([Object? Function(T)? keySelector]) {
    if (keySelector == null) {
      // 使用 == 进行比较
      return toSet().toList();
    }
    final seen = <Object?>{};
    final result = <T>[];
    for (var item in this) {
      final key = keySelector(item);
      if (seen.add(key)) {
        result.add(item);
      }
    }
    return result;
  }

}

extension ListEquals<T> on List<T> {
  bool equalsAll(List<T> other) {
    if (length != other.length) return false;
    for (int i = 0; i < length; i++) {
      if (this[i] != other[i]) return false;
    }
    return true;
  }
}

extension IterableExt<T> on Iterable<T> {
  /// 在元素之间插入分隔符
  ///
  /// 示例：
  /// ```dart
  /// [1, 2, 3].separateWith(0)       // [1, 0, 2, 0, 3]
  /// [1, 2, 3].separateWith(0, first: true)  // [0, 1, 0, 2, 0, 3]
  /// [1, 2, 3].separateWith(0, last: true)   // [1, 0, 2, 0, 3, 0]
  /// ```
  List<T> separateWith(T separator, {bool first = false, bool last = false}) {
    final result = <T>[];

    if (first && isNotEmpty) {
      result.add(separator);
    }

    final iterator = this.iterator;
    if (iterator.moveNext()) {
      result.add(iterator.current);

      while (iterator.moveNext()) {
        result
          ..add(separator)
          ..add(iterator.current);
      }
    }

    if (last && isNotEmpty) {
      result.add(separator);
    }

    return result;
  }
}
