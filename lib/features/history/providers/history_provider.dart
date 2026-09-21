import 'dart:async';

import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/database/extensions/history_extension.dart';
import 'package:clipshare/core/database/tables/history.dart';
import 'package:clipshare/core/services/history/history_event.dart';
import 'package:clipshare/core/services/history/history_recorder_provider.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:clipshare/shared/utils/sorted_list.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:synchronized/synchronized.dart';

import '../../../core/database/app_tables.dart';

part 'history_provider.g.dart';

/// 历史列表状态类型，避免 Riverpod 生成器直接展开 Drift 生成的类型
typedef HistoryList = SortedList<History>;

/// 历史列表状态，后续由历史业务模块负责加载、追加和刷新。
@Riverpod(keepAlive: true)
class HistoriesNotifier extends _$HistoriesNotifier {
  static const tag = 'HistoriesNotifier';

  final _controller = StreamController<HistoryDeltaEvent>.broadcast();

  /// 事件触发后合并刷新 state 的静默窗口，窗口内多次事件只产生一次通知。
  static const refreshDebounce = Duration(milliseconds: 100);

  HistoryList _recentHistories = SortedList(
    comparator: historyComparator,
    capacity: historyPageSize,
    deduplicate: true,
    keyOf: historyKeyOf,
  );

  /// 合并刷新的定时器；事件仍即时写入 [_recentHistories]，仅延迟通知时间点。
  Timer? _flushTimer;
  var _searching = false;
  var _loadingMore = false;
  var _hasMore = true;
  final _lock = Lock();

  bool get searching => _searching;

  set searching(bool value) {
    _searching = value;
    if (!_searching) {
      _recentHistories = SortedList.from(
        _recentHistories.take(historyPageSize),
        comparator: historyComparator,
        deduplicate: true,
        keyOf: historyKeyOf,
      );
      _scheduleRefresh();
    }
  }

  /// 最新的一条历史。
  ///
  /// 列表按“置顶优先、id 降序”分段：置顶段在头部、其后为非置顶段，两段各自
  /// id 降序。因此 id 最大的记录只可能出现在
  /// 置顶段第一项或非置顶段第一项，仅需扫描置顶段即可确定，无需遍历整个列表。
  History? get latest {
    History? result;
    for (final item in _recentHistories) {
      if (result == null || item.id > result.id) {
        result = item;
      }
      if (!item.top) {
        // 遇到第一个非置顶项，它即非置顶段 id 最大，后续项 id 更小，到此即可结束。
        break;
      }
    }
    return result;
  }

  @override
  HistoryList build() {
    unawaited(_listen());
    ref.onDispose(_controller.close);
    return _recentHistories;
  }

  void addDelta(HistoryDeltaEvent delta) {
    _controller.add(delta);
  }

  @override
  bool updateShouldNotify(
    HistoryList previous,
    HistoryList next,
  ) {
    // SortedList 为可变容器且未实现 ==，默认按值比较时同一引用会跳过通知；
    // 这里恒为 true，保证每次 state 赋值（即使引用相同）都刷新监听方。
    return true;
  }

  Future<void> _listen() async {
    //读取原始处理转发到内部事件流
    final recorder = ref.read(historyRecorderProvider.notifier);
    recorder.events.listen(_controller.add);

    final db = await ref.read(appDbProvider.future);
    _recentHistories = SortedList.from(
      await db.historyDao.getHistoriesTop100(),
      comparator: historyComparator,
      capacity: historyPageSize,
      deduplicate: true,
      keyOf: historyKeyOf,
    );
    _hasMore = _recentHistories.length >= historyPageSize;
    state = _recentHistories;
    await for (final event in _controller.stream) {
      try {
        final history = event.history;
        if (event.isAdd) {
          _recentHistories.add(history);
        } else if (event.isUpdate) {
          _recentHistories.replaceFirst((item) => item.id == history.id,
              history);
        } else {
          //delete
          _recentHistories.removeWhere((item) => item.id == history.id);
        }
        _scheduleRefresh();
      } catch (err, stack) {
        logger.error(tag, err, stack);
      }
    }
  }

  /// 重新加载实时历史的第一页。
  Future<void> refresh() async {
    await _lock.synchronized(_refresh);
  }

  Future<void> _refresh() async {
    final db = await ref.read(appDbProvider.future);
    final list = await db.historyDao.getHistoriesTop100();
    _recentHistories = SortedList.from(
      list,
      comparator: historyComparator,
      capacity: historyPageSize,
      deduplicate: true,
      keyOf: historyKeyOf,
    );
    _hasMore = list.length >= historyPageSize;
    state = _recentHistories;
  }

  /// 分页加载实时历史，并在追加期间避免重复请求。
  Future<void> loadMore() async {
    await _lock.synchronized(_loadMore);
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _recentHistories.isEmpty) return;
    _loadingMore = true;
    try {
      if (!_hasMore || _recentHistories.isEmpty) return;
      final db = await ref.read(appDbProvider.future);
      final page = await db.historyDao.getHistoriesPage(_recentHistories.last.id, const []);
      _hasMore = page.length >= historyPageSize;
      if (page.isEmpty) return;
      _recentHistories.setUnbounded();
      _recentHistories.addAll(page);
      state = _recentHistories;
    } finally {
      _loadingMore = false;
    }
  }

  /// 回到顶部时保留当前列表第一页，并重置下一次分页起点。
  Future<void> trimToFirstPage() async {
    await _lock.synchronized(() {
      _recentHistories.setBounded(historyPageSize);
      _hasMore = _recentHistories.length >= historyPageSize;
      state = _recentHistories;
    });
  }

  /// 在刷新窗口内合并通知：每次都基于最新的 [_recentHistories] 赋值，
  /// 因此不会丢失记录，只是把高频事件的多次 UI 刷新聚合成一次。
  void _scheduleRefresh() {
    _flushTimer?.cancel();
    _flushTimer = Timer(refreshDebounce, () {
      state = _recentHistories;
    });
  }
}
