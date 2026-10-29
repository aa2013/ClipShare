import 'package:clipshare/core/constants/platform_constants.dart';
import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/services/device/device_provider.dart';
import 'package:clipshare/core/services/tag/tag_provider.dart';
import 'package:clipshare/features/history/providers/history_export_provider.dart';
import 'package:clipshare/features/history/providers/history_provider.dart';
import 'package:clipshare/features/history/providers/search_provider.dart';
import 'package:clipshare/features/history/widgets/filter/history_filter.dart';
import 'package:clipshare/features/history/widgets/history_list_view.dart';
import 'package:clipshare/features/home/providers/drawer_provider.dart';
import 'package:clipshare/shared/extensions/context_extension.dart';
import 'package:clipshare/shared/widgets/loading/loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  @override
  Widget build(BuildContext context) {
    final search = ref.watch(searchProvider);
    final realtimeList = ref.watch(historiesProvider);
    final searchNotifier = ref.read(searchProvider.notifier);
    final historiesNotifier = ref.read(historiesProvider.notifier);
    final exportNotifier = ref.read(historyExportProvider.notifier);

    //设备/标签变化时刷新筛选数据源
    ref.listen(deviceProvider, (_, __) => searchNotifier.loadCondition());
    ref.listen(tagProvider, (_, __) => searchNotifier.loadCondition());

    //搜索态展示搜索结果，否则展示实时历史流
    final list = search.searching ? search.list : realtimeList;
    //用户主动查询期间用加载动画占位，避免列表闪烁
    final showLoading = search.searching && search.loading;

    return Column(
      children: [
        HistoryFilter(
          value: search.filter,
          devices: search.devices,
          tags: search.tags,
          sources: search.sources,
          showFillColor: isDesktop || !context.isCompactScreen,
          showSearchRow: !context.isCompactScreen,
          onChanged: searchNotifier.updateFilter,
          onSearch: searchNotifier.search,
          onExport: () => exportNotifier.export(
            context,
            (lastId) {
              final db = ref.read(appDbProvider).requireValue;
              return db.historyDao.getHistoriesPageByFilter(
                ref.read(searchProvider).filter,
                true,
                lastId,
              );
            },
          ),
          onShowDetail: (detail) => ref.read(drawerProvider).controller.push(detail, null),
        ),
        Expanded(
          child: showLoading
              ? const Loading()
              : ClipListView(
                  list: list,
                  onExport: (loadDataFunc) => exportNotifier.export(context, loadDataFunc),
                  onLoadMoreData: () async {
                    if (search.searching) {
                      await searchNotifier.loadMore();
                    } else {
                      await historiesNotifier.loadMore();
                    }
                  },
                  onRefresh: () async {
                    if (search.searching) {
                      await searchNotifier.refresh();
                    } else {
                      await historiesNotifier.refresh();
                    }
                  },
                  onBackToTop: () async {
                    if (search.searching) {
                      await searchNotifier.trimToFirstPage();
                    } else {
                      await historiesNotifier.trimToFirstPage();
                    }
                  },
                ),
        ),
      ],
    );
  }
}
