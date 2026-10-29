import 'package:clipshare/features/data_cleanup/pages/data_cleanup_page.dart';
import 'package:clipshare/features/settings/enums/settings_section.dart';
import 'package:clipshare/features/settings/pages/settings_section_view_base.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 设置分区中的数据清理适配视图，复用数据清理页面。
class SettingsDataCleanupPage extends SettingsSectionView {
  const SettingsDataCleanupPage({
    super.key,
    super.embedded,
  }) : super(section: SettingsSection.dataCleanup);

  @override
  List<Widget> buildCards(BuildContext context, WidgetRef ref) {
    return [const DataCleanupPage()];
  }

  @override
  List<SettingsSearchItem> buildSearchItems(BuildContext context, WidgetRef ref) {
    return [
      SettingsSearchItem(
        section: section,
        searchKeys: const [TranslationKey.dataCleanup],
        searchId: TranslationKey.dataCleanup.name,
      ),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 设置二级页面已经提供标题和滚动容器，直接复用数据清理内容。
    return const DataCleanupPage();
  }
}
