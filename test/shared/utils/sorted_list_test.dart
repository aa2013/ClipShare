import 'package:clipshare/shared/utils/sorted_list.dart';
import 'package:flutter_test/flutter_test.dart';

/// 测试辅助：实现 Comparable 的自定义对象。
class _Word implements Comparable<_Word> {
  final String text;

  const _Word(this.text);

  @override
  int compareTo(_Word other) => text.compareTo(other.text);

  @override
  bool operator ==(Object other) => other is _Word && other.text == text;

  @override
  int get hashCode => text.hashCode;
}

/// 测试辅助：未实现 Comparable 的普通对象。
class _Plain {}

void main() {
  group('default comparator', () {
    test('add in random order sorts ascending automatically', () {
      final list = SortedList<int>();
      list.addAll([5, 1, 3, 2, 4]);
      expect(list.toList(), [1, 2, 3, 4, 5]);
    });

    test('custom objects sort by Comparable', () {
      final list = SortedList<_Word>();
      list.addAll([
        const _Word('banana'),
        const _Word('apple'),
        const _Word('cherry'),
      ]);
      expect(list.map((e) => e.text).toList(), ['apple', 'banana', 'cherry']);
    });

    test(
      'throws ArgumentError when elements are not Comparable '
      'and no comparator is provided',
      () {
        expect(
          () => SortedList<_Plain>.from([_Plain(), _Plain()]),
          throwsArgumentError,
        );
      },
    );

    test('duplicates are kept and stay ordered', () {
      final list = SortedList<int>();
      list.addAll([3, 1, 3, 2, 3]);
      expect(list.toList(), [1, 2, 3, 3, 3]);
    });
  });

  group('custom comparator', () {
    test('descending comparator keeps list sorted descending', () {
      final list = SortedList<int>(comparator: (a, b) => b.compareTo(a));
      list.addAll([1, 3, 2]);
      expect(list.toList(), [3, 2, 1]);
    });
  });

  group('fromList constructor', () {
    test('constructs from an unsorted list', () {
      final list = SortedList.from([5, 1, 3, 2]);
      expect(list.toList(), [1, 2, 3, 5]);
    });

    test('bounded constructor keeps only the smallest capacity elements', () {
      final list = SortedList.from([5, 1, 3, 2, 4], capacity: 3);
      expect(list.isBounded, isTrue);
      expect(list.capacity, 3);
      expect(list.toList(), [1, 2, 3]);
    });
  });

  group('bounded capacity', () {
    test('adding a larger value drops the new value when full', () {
      final list = SortedList<int>(capacity: 3);
      list.addAll([10, 20, 30]);
      list.add(40);
      expect(list.toList(), [10, 20, 30]);
    });

    test('adding a smaller value keeps it and drops the largest when full', () {
      final list = SortedList<int>(capacity: 3);
      list.addAll([10, 20, 30]);
      list.add(5);
      expect(list.toList(), [5, 10, 20]);
    });

    test('bounded discards the numerically smallest under a descending comparator', () {
      final list = SortedList<int>(
        comparator: (a, b) => b.compareTo(a),
        capacity: 3,
      );
      list.addAll([1, 2, 3]);
      list.add(50);
      expect(list.toList(), [50, 3, 2]);
    });

    test('addAll truncates when over capacity', () {
      final list = SortedList<int>(capacity: 2);
      list.addAll([3, 1, 2, 4, 5]);
      expect(list.toList(), [1, 2]);
    });
  });

  group('bounded/unbounded switch', () {
    test('setBounded() reuses the most recently configured capacity', () {
      final list = SortedList<int>(capacity: 5);
      list.addAll([1, 2, 3, 4, 5]);
      list.setBounded(3);
      list.setUnbounded();
      list.addAll([9, 8]);
      expect(list.toList(), [1, 2, 3, 8, 9]);
      list.setBounded();
      expect(list.capacity, 3);
      expect(list.toList(), [1, 2, 3]);
    });

    test('setBounded(c) replaces the capacity and truncates', () {
      final list = SortedList<int>(capacity: 5);
      list.addAll([1, 2, 3, 4, 5]);
      list.setBounded(2);
      expect(list.toList(), [1, 2]);
      list.setBounded(4);
      list.addAll([6, 7, 8]);
      expect(list.toList(), [1, 2, 6, 7]);
    });

    test('setBounded() throws StateError without any configured capacity', () {
      final list = SortedList<int>()..addAll([1, 2, 3]);
      expect(() => list.setBounded(), throwsStateError);
      list.setBounded(2);
      expect(list.toList(), [1, 2]);
    });

    test('adding is not truncated after setUnbounded', () {
      final list = SortedList<int>(capacity: 2);
      list.addAll([3, 1]);
      list.setUnbounded();
      list.add(4);
      expect(list.isBounded, isFalse);
      expect(list.toList(), [1, 3, 4]);
    });
  });

  group('replaceFirst', () {
    test('returns the old value and keeps order on a match', () {
      final list = SortedList<int>();
      list.addAll([1, 3, 4, 7]);
      final old = list.replaceFirst((e) => e == 3, 5);
      expect(old, 3);
      expect(list.toList(), [1, 4, 5, 7]);
    });

    test('returns null without changing the list when no match', () {
      final list = SortedList<int>()..addAll([1, 3]);
      expect(list.replaceFirst((e) => e == 99, 0), isNull);
      expect(list.toList(), [1, 3]);
    });

    test('replacement stays within capacity when bounded', () {
      final list = SortedList<int>(capacity: 3);
      list.addAll([1, 5, 10]);
      final old = list.replaceFirst((e) => e == 10, 3);
      expect(old, 10);
      expect(list.toList(), [1, 3, 5]);
    });
  });

  group('destructive write methods', () {
    test('all throw UnsupportedError', () {
      final list = SortedList<int>()..addAll([1, 2]);
      expect(() => list[0] = 3, throwsUnsupportedError);
      expect(() => list.insert(0, 3), throwsUnsupportedError);
      expect(() => list.insertAll(0, [3]), throwsUnsupportedError);
      expect(() => list.setAll(0, [3]), throwsUnsupportedError);
      expect(() => list.setRange(0, 1, [3]), throwsUnsupportedError);
      expect(() => list.replaceRange(0, 1, [3]), throwsUnsupportedError);
      expect(() => list.fillRange(0, 1, 3), throwsUnsupportedError);
      expect(() => list.shuffle(), throwsUnsupportedError);
      expect(() => list.length = 3, throwsUnsupportedError);
      expect(list.toList(), [1, 2]);
    });
  });

  group('removal keeps the list ordered', () {
    test('removeAt / removeWhere / clear', () {
      final list = SortedList<int>()..addAll([1, 2, 3, 4, 5]);
      expect(list.removeAt(2), 3);
      expect(list.toList(), [1, 2, 4, 5]);
      list.removeWhere((e) => e.isEven);
      expect(list.toList(), [1, 5]);
      list.clear();
      expect(list, isEmpty);
    });
  });

  group('deduplicate', () {
    test('deduplicate defaults to false and keeps duplicates', () {
      final list = SortedList<int>()..addAll([3, 1, 3, 2, 3]);
      expect(list.toList(), [1, 2, 3, 3, 3]);
    });

    test('add ignores duplicates using the element itself when keyOf is null', () {
      final list = SortedList<int>(deduplicate: true);
      list..add(1)..add(2)..add(1)..add(3)..add(2);
      expect(list.toList(), [1, 2, 3]);
    });

    test('addAll ignores duplicates using the element itself when keyOf is null', () {
      final list = SortedList<int>(deduplicate: true);
      list.addAll([3, 1, 3, 2, 1, 2, 3]);
      expect(list.toList(), [1, 2, 3]);
    });

    test('custom keyOf decides which elements are duplicates and keeps order', () {
      // 按首字母取键：同一首字母只保留一个。
      final list = SortedList<String>(
        deduplicate: true,
        keyOf: (s) => s[0],
      );
      list.addAll(['apple', 'banana', 'avocado', 'cherry', 'blueberry']);
      expect(list.toList(), ['apple', 'banana', 'cherry']);
    });

    test('duplicates can be re-added after removal', () {
      final list = SortedList<int>(deduplicate: true)..addAll([1, 2]);
      list.removeAt(1);
      list.add(2);
      expect(list.toList(), [1, 2]);
    });

    test('addAll deduplicates and truncates within capacity', () {
      final list = SortedList<int>(
        deduplicate: true,
        keyOf: (e) => e,
        capacity: 3,
      );
      // 去重后为 [1,2,3,5,8]，超容量截断保留排序前 3 个。
      list.addAll([5, 5, 1, 2, 8, 2, 3]);
      expect(list.toList(), [1, 2, 3]);
    });

    test('replaceFirst rejects a replacement that collides with an existing key', () {
      final list = SortedList<String>(
        deduplicate: true,
        keyOf: (s) => s[0],
      )..addAll(['apple', 'banana']);
      // apricot 首字母为 a，与现存 apple 撞键，替换 banana 应被拒绝。
      expect(list.replaceFirst((e) => e == 'banana', 'apricot'), isNull);
      expect(list.toList(), ['apple', 'banana']);
      // 替换为不同键的新项正常生效。
      expect(list.replaceFirst((e) => e == 'apple', 'cherry'), 'apple');
      expect(list.toList(), ['banana', 'cherry']);
    });

    test('replaceFirst allows a replacement sharing the replaced element key', () {
      final list = SortedList<String>(
        deduplicate: true,
        keyOf: (s) => s[0],
      )..addAll(['apple', 'banana']);
      // apricot 与 apple 同为首字母 a，但冲突键正是被替换项自身，应放行。
      expect(list.replaceFirst((e) => e == 'apple', 'apricot'), 'apple');
      expect(list.toList(), ['apricot', 'banana']);
    });

    test('keyOf returning null deduplicates all null-keyed elements', () {
      final list = SortedList<String>(
        deduplicate: true,
        keyOf: (s) => s == 'nul-a' || s == 'nul-b' ? null : s[0],
      );
      // 排序后为 [apple, nul-a, nul-b]，nul-a 与 nul-b 键均为 null，后者被去重。
      list.addAll(['nul-a', 'apple', 'nul-b']);
      expect(list.toList(), ['apple', 'nul-a']);
    });

    test('replaceFirst falls back to linear check once key cache is invalidated', () {
      final list = SortedList<String>(
        deduplicate: true,
        keyOf: (s) => s[0],
      )..addAll(['apple', 'banana', 'cherry']);
      // 删除令键缓存失效（置 null）；列表现为 [apple, cherry]。
      list.removeWhere((e) => e == 'banana');
      // cherry 首字母为 c，与现存 cherry 撞键，替换 apple 应被拒绝。
      expect(list.replaceFirst((e) => e == 'apple', 'cherry'), isNull);
      expect(list.toList(), ['apple', 'cherry']);
      // apricot 撞的是被替换项 apple 自身的键，应放行。
      expect(list.replaceFirst((e) => e == 'apple', 'apricot'), 'apple');
      expect(list.toList(), ['apricot', 'cherry']);
    });

    test('add keeps dedup working after truncation invalidates cache', () {
      final list = SortedList<int>(
        deduplicate: true,
        keyOf: (e) => e,
        capacity: 2,
      );
      list.addAll([1, 2]); // [1,2]
      list.add(3); // 新元素 3 被截断丢弃，键缓存失效
      list.add(0); // 旧元素 2 被截断丢弃，键缓存再次失效
      expect(list.toList(), [0, 1]);
      // 已被丢弃的 2 可再次加入（若缓存残留会误拒）。
      list.add(2); // 插入 [0,1,2]，截断再丢弃 2
      expect(list.toList(), [0, 1]);
    });

    test('capacity zero keeps an empty deduplicated list', () {
      final list = SortedList<int>(
        deduplicate: true,
        keyOf: (e) => e,
        capacity: 0,
      );
      list..add(1)..addAll([2, 2, 3]);
      expect(list, isEmpty);
    });
  });

  group('capacity validation', () {
    test('negative capacity throws ArgumentError', () {
      expect(() => SortedList<int>(capacity: -1), throwsArgumentError);
      final list = SortedList<int>(capacity: 3);
      expect(() => list.setBounded(-1), throwsArgumentError);
    });
  });
}