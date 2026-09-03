import 'dart:async';

import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/database/tables/app_info.dart';
import 'package:clipshare/core/database/tables/device.dart';
import 'package:clipshare/core/database/tables/history.dart';
import 'package:clipshare/core/providers/device/device_provider.dart';
import 'package:clipshare/core/providers/tag/tag_provider.dart';
import 'package:clipshare/features/history/providers/history_provider.dart';
import 'package:clipshare/shared/models/search_filter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/app_tables.dart';

part 'search_provider.g.dart';

/// 历史搜索状态：搜索条件、筛选数据源与搜索结果。
class SearchState {
  /// 当前搜索条件。
  final SearchFilter filter;

  /// 可筛选设备（本机在前）。
  final List<Device> devices;

  /// 全部标签名。
  final List<String> tags;

  /// 全部来源（应用）信息。
  final List<AppInfo> sources;

  /// 是否处于搜索态；为 false 时页面展示实时历史流。
  final bool searching;

  /// 是否正在查询。
  final bool loading;

  /// 是否还有更多分页数据。
  final bool hasMore;

  /// 当前搜索结果列表。
  final List<History> list;

  const SearchState({
    required this.filter,
    this.devices = const [],
    this.tags = const [],
    this.sources = const [],
    this.searching = false,
    this.loading = false,
    this.hasMore = false,
    this.list = const [],
  });

  /// 搜索条件是否生效（与空条件比较）。
  bool get hasActiveFilter => filter.toString() != SearchFilter().toString();

  SearchState copyWith({
    SearchFilter? filter,
    List<Device>? devices,
    List<String>? tags,
    List<AppInfo>? sources,
    bool? searching,
    bool? loading,
    bool? hasMore,
    List<History>? list,
  }) {
    return SearchState(
      filter: filter ?? this.filter,
      devices: devices ?? this.devices,
      tags: tags ?? this.tags,
      sources: sources ?? this.sources,
      searching: searching ?? this.searching,
      loading: loading ?? this.loading,
      hasMore: hasMore ?? this.hasMore,
      list: list ?? this.list,
    );
  }
}

/// 历史搜索状态源：页面负责把它接入受控过滤器组件与列表。
@Riverpod(keepAlive: true)
class SearchNotifier extends _$SearchNotifier {

  /// 搜索框实时搜索防抖。
  static const contentDebounce = Duration(milliseconds: 200);

  Timer? _contentDebounce;

  /// 实时历史变化后重查搜索结果的防抖。
  Timer? _refreshDebounce;

  @override
  SearchState build() {
    ref.onDispose(() {
      _contentDebounce?.cancel();
      _refreshDebounce?.cancel();
    });
    //搜索态下实时历史变化时，防抖重查，使符合条件的新记录即时出现
    ref.listen(historiesProvider, (_, __) {
      if (state.searching) {
        _scheduleRefresh();
      }
    });
    //首载筛选数据源（设备/标签/来源）
    unawaited(loadCondition());
    return SearchState(filter: SearchFilter());
  }

  /// 加载筛选数据源：设备（含本机）、标签、来源。
  Future<void> loadCondition() async {
    final deviceState = await ref.read(deviceProvider.future);
    final tagState = await ref.read(tagProvider.future);
    final db = await ref.read(appDbProvider.future);
    final sources = await db.appInfoDao.getAllAppInfos();

    final self = deviceState.self;
    final devices = <Device>[self];
    for (final dev in deviceState.list) {
      if (dev.guid != self.guid) {
        devices.add(dev);
      }
    }
    state = state.copyWith(
      devices: devices,
      tags: tagState.list,
      sources: sources,
    );
  }

  /// 更新搜索条件：条件生效时查询，清空时回退实时列表。
  void updateFilter(SearchFilter filter) {
    final searching = filter.toString() != SearchFilter().toString();
    state = state.copyWith(filter: filter, searching: searching);
    if (searching) {
      unawaited(search());
    } else {
      state = state.copyWith(list: const [], hasMore: false);
    }
  }

  /// 搜索框输入变化：防抖后应用条件并查询。
  void setContent(String content) {
    _contentDebounce?.cancel();
    _contentDebounce = Timer(contentDebounce, () {
      updateFilter(state.filter.copyWith(content: content));
    });
  }

  /// 清空搜索条件，恢复实时列表。
  void reset() {
    _contentDebounce?.cancel();
    state = state.copyWith(
      filter: SearchFilter(),
      searching: false,
      list: const [],
      hasMore: false,
    );
  }

  /// 搜索态下实时列表变化时，防抖重新查询，让匹配的新历史进入结果。
  void _scheduleRefresh() {
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(contentDebounce, () {
      if (state.searching) {
        unawaited(search());
      }
    });
  }

  /// 查询搜索首页。
  Future<void> search() async {
    final filter = state.filter;
    state = state.copyWith(searching: true, loading: true);
    final db = await ref.read(appDbProvider.future);
    final list = await db.historyDao.getHistoriesPageByFilter(filter, false);
    state = state.copyWith(
      list: list,
      loading: false,
      hasMore: list.length >= historyPageSize,
    );
  }

  /// 分页加载更多。
  Future<void> loadMore() async {
    //todo 按当前 filter 分页加载更多
  }
}
