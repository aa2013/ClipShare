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
}

extension ListEquals on List<int> {
  bool equals(List<int> other) {
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
