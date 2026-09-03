import 'package:clipshare/core/extensions/context_extension.dart';
import 'package:clipshare/features/debug/pages/debug_page.dart';
import 'package:clipshare/features/history/pages/history_page.dart';
import 'package:clipshare/features/home/pages/home_compact_page.dart';
import 'package:clipshare/features/home/pages/home_wide_page.dart';
import 'package:clipshare/features/home/providers/drawer_provider.dart';
import 'package:clipshare/features/home/providers/navigation_provider.dart';
import 'package:clipshare/features/settings/pages/settings.dart';
import 'package:clipshare/shared/models/keyboard_shortcut.dart';
import 'package:clipshare/shared/widgets/base/custom_keyboard_listener.dart';
import 'package:clipshare/shared/widgets/layouts/my_navigation_rail.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomeState();
}

class _HomeState extends ConsumerState<HomePage> {
  var index = 0;
  static const rulesPageKey = Key('rules-page');
  static const notShowCompactPageKeys = [rulesPageKey];
  static const navIconSize = 20.0;
  late final List<Widget> pages;

  @override
  void initState() {
    pages = [
      const HistoryPage(),
      const Text('pages2'),
      const Text('pages3'),
      const Text(
        'pages4',
        key: rulesPageKey,
      ),
      const SettingsPage(),
    ];
    assert(() {
      pages.add(const DebugPage());
      return true;
    }());
    super.initState();
  }

  ///根据统一导航数据构建宽屏导航菜单。
  List<MyNavigationItem> buildWideNavItems(List<HomeNavigationItemData> items) {
    return items
        .map(
          (item) => MyNavigationItem(
            icon: Icon(
              item.icon,
              size: navIconSize,
            ),
            label: Text(item.label),
            tooltip: item.label,
          ),
        )
        .toList();
  }

  ///根据统一导航数据构建窄屏导航菜单。
  List<BottomNavigationBarItem> buildCompactNavItems(List<HomeNavigationItemData> items) {
    return items
        .where((item) => item.showInCompact)
        .map(
          (item) => BottomNavigationBarItem(
            icon: Icon(
              item.icon,
              size: navIconSize,
            ),
            label: item.label,
            tooltip: item.label,
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final navItems = ref.watch(homeNavigationItemsProvider);
    List<Widget> showPages;
    Widget content;
    if (context.isCompactScreen) {
      showPages = pages.where((page) => !notShowCompactPageKeys.contains(page.key)).toList();
      content = HomeCompactPage(
        pages: showPages,
        navItems: buildCompactNavItems(navItems),
      );
    }else{
      showPages = pages;
    }
    content = HomeWidePage(
      navItems: buildWideNavItems(navItems),
      pages: showPages,
    );
    return CustomKeyboardListener(
      shortcuts: [
        KeyboardShortcut(
          physicalKeys: {PhysicalKeyboardKey.escape},
          onTrigger: handleEscapeShortcut,
        ),
      ],
      child: content,
    );
  }

  /// 处理页面级 Esc 快捷键；抽屉是覆盖层，应优先于页面多选状态关闭。
  void handleEscapeShortcut() {
    final drawer = ref.read(drawerProvider).controller;
    if (!drawer.isEmpty) {
      drawer.popWithAnimation();
      return;
    }
    //todo
    // if (appConfig.isMultiSelectionMode(currentPageController)) {
    //   appConfig.disableMultiSelectionMode(true);
    //   notifyMultiSelectionPopScopeDisable();
    // }
  }
}
