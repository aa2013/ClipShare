import 'package:clipshare/core/extensions/context_extension.dart';
import 'package:clipshare/features/home/pages/home_compact_page.dart';
import 'package:clipshare/features/home/pages/home_wide_page.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/widgets/layouts/my_navigation_rail.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<StatefulWidget> createState() => _HomeState();
}

class _NavItem {
  final Key? key;
  final IconData icon;
  final String label;

  _NavItem({
    this.key,
    required this.icon,
    required this.label,
  });
}

class _HomeState extends State<HomePage> {
  var index = 0;
  static const rulesNavItemKey = Key('rules-nav');
  static const rulesPageKey = Key('rules-page');
  static const notShowCompactNavItemKeys = [rulesNavItemKey];
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
      const Text('pages5'),
    ];
    assert(() {
      pages.add(const Text('Debug'));
      return true;
    }());
    super.initState();
  }

  ///初始化导航栏
  List<_NavItem> initNavBarItems() {
    final items = [
      _NavItem(
        icon: Icons.history,
        label: TranslationKey.historyRecord.tr,
      ),
      _NavItem(
        icon: Icons.devices_rounded,
        label: TranslationKey.myDevice.tr,
      ),
      _NavItem(
        icon: Icons.sync_alt_outlined,
        label: TranslationKey.fileTransfer.tr,
      ),
      _NavItem(
        key: rulesNavItemKey,
        icon: Icons.code_outlined,
        label: TranslationKey.rulesManagement.tr,
      ),
      _NavItem(
        icon: Icons.settings,
        label: TranslationKey.appSettings.tr,
      ),
    ];
    assert(() {
      items.add(
        _NavItem(
          icon: Icons.bug_report_outlined,
          label: 'Debug',
        ),
      );
      return true;
    }());
    return items;
  }

  ///构建宽屏导航菜单
  List<MyNavigationItem> buildWideNavItems() {
    final items = initNavBarItems();
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

  ///构建窄屏导航菜单
  List<BottomNavigationBarItem> buildCompactNavItems() {
    final items = initNavBarItems();
    return items
        .where((item) => !notShowCompactNavItemKeys.contains(item.key))
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
    List<Widget> showPages;
    if (context.isCompactScreen) {
      showPages = pages.where((page) => !notShowCompactPageKeys.contains(page.key)).toList();
      return HomeCompactPage(
        pages: showPages,
        navItems: buildCompactNavItems(),
      );
    }
    showPages = pages;
    return HomeWidePage(
      navItems: buildWideNavItems(),
      pages: showPages,
    );
  }
}
