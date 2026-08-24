import 'package:clipshare/core/database/app_database.dart';
import 'package:clipshare/core/database/extensions/history_extension.dart';
import 'package:clipshare/shared/enums/history_content_type.dart';
import 'package:clipshare/shared/utils/sorted_list.dart';
import 'package:flutter_test/flutter_test.dart';

/// 构造测试用 [History]。
History _history({required int id, required bool top}) {
  return History(
    id: id,
    uid: 1,
    time: '2026-01-01 00:00:00',
    content: '',
    type: HistoryContentType.text.value,
    devId: '',
    top: top,
    sync: false,
    size: 0,
  );
}

void main() {
  group('historyComparator', () {
    test('pinned takes priority over non-pinned', () {
      expect(
        historyComparator(_history(id: 1, top: true), _history(id: 100, top: false)),
        lessThan(0),
      );
      expect(
        historyComparator(_history(id: 100, top: false), _history(id: 1, top: true)),
        greaterThan(0),
      );
    });

    test('same pinned sorts by id desc', () {
      expect(
        historyComparator(
          _history(id: 3, top: true),
          _history(id: 5, top: true),
        ),
        equals(1),
      );
    });

    test('same non-pinned sorts by id desc', () {
      expect(
        historyComparator(_history(id: 5, top: false), _history(id: 3, top: false)),
        lessThan(0),
      );
    });

    test('works with SortedList auto sorting', () {
      final list = SortedList<History>(comparator: historyComparator);
      list.addAll([
        _history(id: 2, top: false),
        _history(id: 1, top: true),
        _history(id: 3, top: false),
        _history(id: 4, top: true),
      ]);
      expect(list.map((e) => e.id).toList(), [4, 1, 3, 2]);
    });
  });
}
