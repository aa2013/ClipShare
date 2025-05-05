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

  List<T> separateWith(T separator, {bool first = false, bool last = false}) {
    final result = <T>[];
    if (first) {
      result.add(separator);
    }
    for (var i = 0; i < length; i++) {
      result.add(this[i]);
      if (i != length - 1) {
        result.add(separator);
      }
    }
    if (last) {
      result.add(separator);
    }
    return result;
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
