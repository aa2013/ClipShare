import 'package:clipshare/core/extensions/context_extension.dart';
import 'package:clipshare/features/home/pages/home_compact_page.dart';
import 'package:clipshare/features/home/pages/home_wide_page.dart';
import 'package:clipshare/features/home/providers/navigation_provider.dart';
import 'package:clipshare/features/settings/pages/settings.dart';
import 'package:clipshare/shared/widgets/layouts/my_navigation_rail.dart';
import 'package:flutter/material.dart';
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
      const Text('pages1'),
      const Text('pages2'),
      const Text('pages3'),
      const Text(
        'pages4',
        key: rulesPageKey,
      ),
      const SettingsPage(),
    ];
    assert(() {
      pages.add(const Text('Debug'));
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
    if (context.isCompactScreen) {
      showPages = pages.where((page) => !notShowCompactPageKeys.contains(page.key)).toList();
      return HomeCompactPage(
        pages: showPages,
        navItems: buildCompactNavItems(navItems),
      );
    }
    showPages = pages;
    return HomeWidePage(
      navItems: buildWideNavItems(navItems),
      pages: showPages,
    );
  }
}
