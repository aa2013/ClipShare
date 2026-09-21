import 'package:clipshare/features/settings/enums/settings_section.dart';
import 'package:clipshare/features/settings/pages/settings_overview.dart';
import 'package:clipshare/features/settings/pages/settings_section_content.dart';
import 'package:clipshare/features/settings/pages/settings_tablet.dart';
import 'package:clipshare/routing/app_routes.dart';
import 'package:clipshare/shared/extensions/context_extension.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (context.isCompactScreen) {
      return SettingsOverviewPage(
        onSectionTap: (section) => _openSection(context, section),
        onSearchItemTap: (item)=>_openSearchItem(context, item),
      );
    }
    return const SettingsTabletPage();
  }

  /// 打开设置分区内容页。
  ///
  /// 规则管理归属独立路由，其余分区统一走分区内容页路由；
  /// [highlightedSearchId] 由搜索结果进入时携带，用于高亮定位到具体设置项。
  void _openSection(
    BuildContext context,
    SettingsSection section, {
    String? highlightedSearchId,
  }) {
    if (section == SettingsSection.rules) {
      context.pushNamed(AppRoutes.rules.name);
      return;
    }
    context.pushNamed(
      AppRoutes.settingsSection.name,
      extra: SettingsSectionRouteArgs(
        section: section,
        highlightedSearchId: highlightedSearchId,
      ),
    );
  }

  void _openSearchItem(BuildContext context, SettingsSearchItem item) {
    _openSection(
      context,
      item.section,
      highlightedSearchId: item.searchId.isEmpty ? null : item.searchId,
    );
  }
}
