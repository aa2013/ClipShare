import 'dart:math';

import 'package:clipshare/core/services/history/missing_data_sync_progress_provider.dart';
import 'package:clipshare/features/home/providers/home_page_index_provider.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/extensions/context_extension.dart';
import 'package:clipshare/shared/utils/consumer_wrapper.dart';
import 'package:clipshare/shared/widgets/base/loading_dots.dart';
import 'package:clipshare/shared/widgets/layouts/my_navigation_rail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeCompactPage extends ConsumerStatefulWidget {
  final List<Widget> pages;
  final List<BottomNavigationBarItem> navItems;

  const HomeCompactPage({
    super.key,
    required this.pages,
    required this.navItems,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _HomeCompactPageState();
}

class _HomeCompactPageState extends ConsumerState<HomeCompactPage> {
  ///紧凑模式首个页面固定为历史页
  static const historyPageIndex = 0;

  int get index => min(ref.watch(homePageIndexProvider), widget.pages.length - 1);

  BottomNavigationBarItem get currentNav => widget.navItems[index];

  @override
  Widget build(BuildContext context) {
    final currentTheme = context.currentTheme;
    return Scaffold(
      appBar: buildAppBar(context),
      body: IndexedStack(
        index: index,
        children: [
          for (var i = 0; i < widget.pages.length; i++)
            TickerMode(
              enabled: i == index,
              child: widget.pages[i],
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: currentTheme.bottomNavigationBarTheme.backgroundColor ?? currentTheme.colorScheme.surface,
        selectedItemColor: currentTheme.bottomNavigationBarTheme.selectedItemColor,
        unselectedItemColor: currentTheme.bottomNavigationBarTheme.unselectedItemColor,
        currentIndex: index,
        onTap: (i) {
          final indexNotifier = ref.read(homePageIndexProvider.notifier);
          indexNotifier.set(i);
        },
        items: widget.navItems,
      ),
    );
  }

  PreferredSizeWidget buildAppBar(BuildContext context) {
    return AppBar(
      title: Row(
        children: [
          currentNav.icon,
          const SizedBox(width: 5),
          consumerWrapper(buildSyncingProgress),
        ],
      ),
      actions: _buildSmallScreenAppBarActions(),
      automaticallyImplyLeading: false,
    );
  }

  Widget buildSyncingProgress(BuildContext context, WidgetRef ref) {
    //历史页且存在进行中的补数批次时，标题位展示聚合进度
    final progress = ref.watch(missingDataSyncProgressProvider);
    final showSyncProgress = index == historyPageIndex && progress.syncing;
    if (showSyncProgress) {
      return LoadingDots(
        text: Text(
          '${TranslationKey.homeAppBarSyncingProgressText.tr}(${progress.sumSeq}/${progress.sumTotal})',
        ),
      );
    }
    return Text(currentNav.label ?? '');
  }

  Widget _buildHistorySearchAppBar() {
    // final historyController = Get.find<HistoryController>();
    // final filterController = historyController.filterController;
    // return _HistorySearchAppBar(
    //   controller: filterController,
    //   onFocusLost: () {
    //     controller.showingHistorySearch.value = false;
    //   },
    // );
    return Container();
  }

  List<Widget>? _buildSmallScreenAppBarActions() {
    //todo
    // return [
    //   Obx(
    //         () {
    //       if (!controller.isHistoryPage || controller.showingHistorySearch.value) {
    //         return const SizedBox.shrink();
    //       }
    //       final historyController = Get.find<HistoryController>();
    //       if (historyController.filterLoading.value) {
    //         return const SizedBox.shrink();
    //       }
    //       return IconButton(
    //         tooltip: TranslationKey.search.tr,
    //         onPressed: _showHistorySearch,
    //         icon: const Icon(Icons.search_rounded),
    //       );
    //     },
    //   ),
    // ];
    return null;
  }
}
