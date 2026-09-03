import 'package:clipshare/l10n/l10n_provider.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'navigation_provider.g.dart';

class HomeNavigationItemData {
  final Key? key;
  final IconData icon;
  final String label;
  final bool showInCompact;

  const HomeNavigationItemData({
    this.key,
    required this.icon,
    required this.label,
    this.showInCompact = true,
  });
}

const _rulesNavItemKey = Key('rules-nav');

/// 生成首页导航项统一数据源。
///
/// 依赖当前翻译对象后，首页、左侧导航和底部导航都会在语言切换完成后重新构建。
@Riverpod(keepAlive: true)
List<HomeNavigationItemData> homeNavigationItems(Ref ref) {
  ref.watch(appLocalizationsProvider);
  return _buildHomeNavigationItems();
}

/// 构建首页导航项基础数据。
///
/// 导航文案在这里统一取值，避免页面层分别拼装时遗漏语言依赖。
List<HomeNavigationItemData> _buildHomeNavigationItems() {
  final items = [
    HomeNavigationItemData(
      icon: Icons.history,
      label: TranslationKey.historyRecord.tr,
    ),
    HomeNavigationItemData(
      icon: Icons.devices_rounded,
      label: TranslationKey.myDevice.tr,
    ),
    HomeNavigationItemData(
      icon: Icons.sync_alt_outlined,
      label: TranslationKey.fileTransfer.tr,
    ),
    HomeNavigationItemData(
      key: _rulesNavItemKey,
      icon: Icons.code_outlined,
      label: TranslationKey.rulesManagement.tr,
      showInCompact: false,
    ),
    HomeNavigationItemData(
      icon: Icons.settings,
      label: TranslationKey.appSettings.tr,
    ),
  ];
  assert(() {
    items.add(
      const HomeNavigationItemData(
        icon: Icons.bug_report_outlined,
        label: 'Debug',
      ),
    );
    return true;
  }());
  return items;
}
