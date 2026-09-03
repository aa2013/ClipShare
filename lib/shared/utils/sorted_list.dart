import 'dart:collection';
import 'dart:math';

/// 有序列表
///
/// 内部始终按构造时传入的比较器排序，
/// `add`/`addAll` 会自动插入到正确位置；支持有界容量，当容量已满时
/// 先插入，再按排序丢弃超界元素。
///
/// 注意：
/// * `insert`、`operator []=`、`setRange` 等会破坏有序不变式的方法为
///   `UnsupportedError`，替换元素请使用 [replaceFirst]。
/// * 删除类方法（`remove`、`removeAt` 等）不会破坏有序不变式，可直接使用。
/// * 开启去重时，“重复”由去重键决定（见 [SortedList.keyOf]，默认取元素
///   自身）；去重键必须稳定，同一元素多次取值应一致，否则去重行为不可靠。
class SortedList<E> extends ListBase<E> {
  /// 实际存储数据，始终保持按 [_compare] 有序。
  final List<E> _list = <E>[];

  /// 构造时固定的比较器，决定排序方向与元素顺序。
  final Comparator<E> _compare;

  /// 当前容量，`null` 表示无界。
  int? _capacity;

  /// 最近一次配置的容量，供无参调用 [setBounded] 时沿用。
  int? _configuredCapacity;

  /// 是否开启去重；开启后 [add]/[addAll] 会过滤键集合中已存在的元素。
  final bool _deduplicate;

  /// 去重键提取函数；为空时用元素自身作为键（依赖其哈希与等值语义）。
  final Object? Function(E e)? _keyOf;

  /// 当前列表的去重键集合缓存，开启去重时按需构建、结构变化后失效。
  ///
  /// 判重通过该集合命中实现 O(1) 均摊，避免追加元素时线性扫描全表。
  Set<Object?>? _keys;

  /// 创建一个自动排序的列表，可选容量与去重。
  ///
  /// * [comparator] 为空时使用默认比较实现，要求元素实现
  ///   [Comparable]，否则在首次比较元素时抛出 [ArgumentError]。
  /// * [capacity] 非负，传入时列表为有界，超出容量后丢弃排序末尾元素；
  ///   为空时列表无界。
  /// * [deduplicate] 默认关闭；开启时 [add]/[addAll] 会排除与键集合中
  ///   已有元素重复的项，使列表不出现重复键。
  /// * [keyOf] 提取去重键，可选；为空时用元素自身作为键（依赖其
  ///   hashCode 与 equals）。开启去重时生效：键只需稳定，即同一元素多次
  ///   取值应一致；多个元素取到同一键会被视为重复，[addAll] 按首次出现
  ///   顺序保留一个。
  SortedList({
    Comparator<E>? comparator,
    int? capacity,
    bool deduplicate = false,
    Object? Function(E e)? keyOf,
  }) : _compare = comparator ?? _defaultComparator<E>(),
       _configuredCapacity = capacity,
       _capacity = capacity,
       _deduplicate = deduplicate,
       _keyOf = keyOf {
    if (capacity != null && capacity < 0) {
      throw ArgumentError.value(
        capacity,
        'capacity',
        'capacity must not be negative',
      );
    }
  }

  /// 从 [elements] 构造，构造后保持有序；有界时仅保留前 [capacity] 个。
  ///
  /// 参数语义与 [SortedList] 构造一致。
  factory SortedList.from(
    Iterable<E> elements, {
    Comparator<E>? comparator,
    int? capacity,
    bool deduplicate = false,
    Object? Function(E e)? keyOf,
  }) {
    final list = SortedList<E>(
      comparator: comparator,
      capacity: capacity,
      deduplicate: deduplicate,
      keyOf: keyOf,
    );
    list.addAll(elements);
    return list;
  }

  /// 当前是否处于有界状态。
  bool get isBounded => _capacity != null;

  /// 当前容量，无界时为 `null`。
  int? get capacity => _capacity;

  /// 最近一次配置的容量（构造时传入或被 [setBounded] 替换），无界且从未
  /// 配置过容量时为 `null`。
  int? get configuredCapacity => _configuredCapacity;

  /// 切换为有界并自动截断排序末尾的超容量元素。
  ///
  /// * [capacity] 传入时替换最近配置的容量并生效。
  /// * [capacity] 为空时沿用最近一次配置的容量；若从未配置过容量（构造时
  ///   无界且未传容量），抛出 [StateError]。
  void setBounded([int? capacity]) {
    if (capacity != null) {
      if (capacity < 0) {
        throw ArgumentError.value(
          capacity,
          'capacity',
          'capacity must not be negative',
        );
      }
      _configuredCapacity = capacity;
      _capacity = capacity;
    } else {
      final configured = _configuredCapacity;
      if (configured == null) {
        throw StateError(
          'No capacity has been configured. Provide one when calling '
          'setBounded().',
        );
      }
      _capacity = configured;
    }
    _truncateIfOverCapacity();
    // 截断可能丢弃元素，键缓存与列表不再一致，作废待重建。
    _keys = null;
  }

  /// 切换为无界，保留当前全部元素。
  void setUnbounded() {
    _capacity = null;
  }

  /// 替换第一个满足 [test] 的元素为 [replacement]，替换后保持有序。
  ///
  /// 返回被替换的元素；未找到符合条件元素时返回 `null`。
  /// 注意：当元素本身为 `null` 时，与“未找到”的返回值无法区分。
  /// 开启去重时，若 [replacement] 与列表内其他元素的去重键相同，为避免
  /// 产生重复，本次替换会被拒绝并同样返回 `null`——调用方可将 `null` 视
  /// 为“未发生替换”，不区分被拒绝还是无匹配，如需区分可另行用
  /// [contains] 复核。
  E? replaceFirst(bool Function(E element) test, E replacement) {
    final index = indexWhere(test);
    if (index == -1) {
      return null;
    }
    final replaced = _list[index];
    if (_deduplicate) {
      final key = _keyOfValue(replacement);
      final keys = _keys;
      if (keys != null) {
        // 被替换项自身的键不算冲突，需排除后再判断。
        if (_keyOfValue(replaced) != key && keys.contains(key)) {
          return null;
        }
      } else {
        for (var i = 0; i < _list.length; i++) {
          if (i != index && _keyOfValue(_list[i]) == key) {
            return null;
          }
        }
      }
    }
    _list.removeAt(index);
    final position = _lowerBound(replacement);
    _list.insert(position, replacement);
    // 结构变化，键缓存作废待重建。
    _keys = null;
    return replaced;
  }

  /// 二分查找 [value] 应插入的位置（第一个大于等于它的下标）。
  int _lowerBound(E value) {
    var low = 0;
    var high = _list.length;
    while (low < high) {
      final mid = (low + high) >> 1;
      if (_compare(_list[mid], value) < 0) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    return low;
  }

  /// 若当前有界且元素数超出容量，丢弃排序末尾的超容量元素，返回是否发生了截断。
  bool _truncateIfOverCapacity() {
    final capacity = _capacity;
    if (capacity != null && _list.length > capacity) {
      _list.removeRange(capacity, _list.length);
      return true;
    }
    return false;
  }

  /// 提取 [value] 的去重键；未配置 [keyOf] 时用元素自身作为键。
  Object? _keyOfValue(E value) {
    final keyOf = _keyOf;
    return keyOf != null ? keyOf(value) : value;
  }

  /// 判断列表是否已存在与 [value] 去重键相同的元素。
  ///
  /// 未开启去重时恒为 [false]；开启时先确保键缓存可用，再通过集合判断，
  /// 单次判重均摊 O(1)。
  bool _isDuplicate(E value) {
    if (!_deduplicate) {
      return false;
    }
    final key = _keyOfValue(value);
    final keys = _keys;
    if (keys != null) {
      return keys.contains(key);
    }
    // 键缓存缺失（列表曾被删除类方法修改），按当前列表重建后再判断。
    final rebuilt = {
      for (final e in _list) _keyOfValue(e),
    };
    _keys = rebuilt;
    return rebuilt.contains(key);
  }

  /// 默认比较实现：要求元素实现 [Comparable]。
  ///
  /// 注意使用裸 `Comparable` 检查，而非 `Comparable<E>`：例如 `int` 实现的是
  /// `Comparable<num>`，泛型 `is Comparable<E>` 会误判。
  static Comparator<E> _defaultComparator<E>() {
    return (E a, E b) {
      final comparable = a;
      if (comparable is Comparable) {
        return comparable.compareTo(b);
      }
      throw ArgumentError(
        'SortedList elements of type ${a.runtimeType} do not implement '
        'Comparable. Provide a custom comparator instead.',
      );
    };
  }

  @override
  int get length => _list.length;

  @override
  set length(int newLength) {
    throw UnsupportedError('SortedList does not allow modifying length directly');
  }

  @override
  E operator [](int index) => _list[index];

  @override
  void operator []=(int index, E value) {
    throw UnsupportedError(
      'SortedList does not allow index assignment. Use replaceFirst or '
      'remove then add instead.',
    );
  }

  /// 按排序插入 [value]；开启去重时若已存在同键元素则忽略。
  /// 有界超容量时丢弃排序末尾元素。
  @override
  void add(E value) {
    if (!_deduplicate) {
      _list.insert(_lowerBound(value), value);
      _truncateIfOverCapacity();
      return;
    }
    if (_isDuplicate(value)) {
      return;
    }
    final key = _keyOfValue(value);
    final before = _list.length;
    _list.insert(_lowerBound(value), value);
    _truncateIfOverCapacity();
    final keys = _keys;
    if (keys != null && _list.length == before + 1) {
      // 未触发截断，键集合与列表仍一致，增量登记新键即可。
      keys.add(key);
    } else {
      // 触发截断（丢弃了元素）或缓存在判重时刚构建、插入后需要回填；统一失效。
      _keys = null;
    }
  }

  /// 批量加入后统一排序；开启去重时保留每个键的第一个元素。
  /// 有界超容量时丢弃排序末尾元素。
  ///
  /// 整体复杂度 O((n+m) log(n+m))：批量加入 + 一次排序 + 单趟去重。
  @override
  void addAll(Iterable<E> iterable) {
    // 先使键缓存脱钩：iterable 迭代中途抛异常时列表可能只加入部分元素，
    // 旧的键缓存与列表现状不再一致，必须失效待重建。
    _keys = null;
    _list.addAll(iterable);
    _list.sort(_compare);
    if (_deduplicate) {
      final seen = <Object?>{};
      var write = 0;
      for (var read = 0; read < _list.length; read++) {
        final key = _keyOfValue(_list[read]);
        if (seen.add(key)) {
          _list[write++] = _list[read];
        }
      }
      if (write < _list.length) {
        _list.removeRange(write, _list.length);
      }
      // 去重后的键集合恰好与列表一一对应，直接复用为缓存。
      _keys = seen;
    }
    if (_truncateIfOverCapacity()) {
      // 截断丢弃了元素，键缓存与列表不一致，作废待重建。
      _keys = null;
    }
  }

  /// 列表始终有序，调用无副作用；传入的 [compare] 不生效。
  @override
  void sort([int Function(E a, E b)? compare]) {
    // 排序不变式由内部维护，无需重新排序。
  }

  @override
  void insert(int index, E element) {
    throw UnsupportedError('SortedList does not allow index insert. Use add instead');
  }

  @override
  void insertAll(int index, Iterable<E> iterable) {
    throw UnsupportedError('SortedList does not allow index insert. Use addAll instead');
  }

  @override
  void setAll(int index, Iterable<E> iterable) {
    throw UnsupportedError('SortedList does not allow index-based batch assignment');
  }

  @override
  void setRange(int start, int end, Iterable<E> iterable, [int skipCount = 0]) {
    throw UnsupportedError('SortedList does not allow index-based batch assignment');
  }

  @override
  void replaceRange(int start, int end, Iterable<E> newContents) {
    throw UnsupportedError('SortedList does not allow index-based batch replacement');
  }

  @override
  void fillRange(int start, int end, [E? fill]) {
    throw UnsupportedError('SortedList does not allow filling a range');
  }

  @override
  void shuffle([Random? random]) {
    throw UnsupportedError('SortedList does not allow shuffling');
  }

  @override
  bool remove(Object? element) {
    final removed = _list.remove(element);
    _keys = null;
    return removed;
  }

  @override
  E removeAt(int index) {
    final removed = _list.removeAt(index);
    _keys = null;
    return removed;
  }

  @override
  E removeLast() {
    final removed = _list.removeLast();
    _keys = null;
    return removed;
  }

  @override
  void removeRange(int start, int end) {
    _list.removeRange(start, end);
    _keys = null;
  }

  @override
  void removeWhere(bool Function(E element) test) {
    _list.removeWhere(test);
    _keys = null;
  }

  @override
  void retainWhere(bool Function(E element) test) {
    _list.retainWhere(test);
    _keys = null;
  }

  @override
  void clear() {
    _list.clear();
    _keys = null;
  }
}
