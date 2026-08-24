import 'dart:math';

import 'package:clipshare/core/extensions/context_extension.dart';
import 'package:flutter/material.dart';

class HomeCompactPage extends StatefulWidget {
  final List<Widget> pages;
  final List<BottomNavigationBarItem> navItems;

  const HomeCompactPage({
    super.key,
    required this.pages,
    required this.navItems,
  });

  @override
  State<StatefulWidget> createState() => _HomeCompactPageState();
}

class _HomeCompactPageState extends State<HomeCompactPage> {
  var index = 0;

  @override
  Widget build(BuildContext context) {
    final currentTheme = context.currentTheme;
    index = min(widget.pages.length - 1, index);
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
        onTap: (i) => setState(() {
          index = i;
        }),
        items: widget.navItems,
      ),
    );
  }

  PreferredSizeWidget buildAppBar(BuildContext context) {
    final navItem = widget.navItems[index];
    final navIcon = navItem.icon;
    final navLabel = navItem.label;
    return AppBar(
      title: Row(
        children: [
          navIcon,
          const SizedBox(width: 5),
          Text(navLabel ?? ''),
        ],
      ),
      actions: _buildSmallScreenAppBarActions(),
      automaticallyImplyLeading: false,
    );
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
