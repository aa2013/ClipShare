import 'package:clipshare/app/modules/clean_data_module/clean_data_page.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/modules/settings_module/pages/settings_section_view_base.dart';
import 'package:clipshare/app/modules/settings_module/settings_section.dart';
import 'package:flutter/material.dart';

/// 设置分区中的清理数据适配视图，复用原清理数据页面和控制器。
class SettingsCleanDataPage extends SettingsSectionView {
  SettingsCleanDataPage({
    super.key,
    super.embedded,
  }) : super(section: SettingsSection.cleanData);

  @override
  List<Widget> buildCards(BuildContext context) {
    return [CleanDataPage(embedded: true)];
  }

  @override
  List<SettingsSearchItem> buildSearchItems(BuildContext context) {
    return [
      SettingsSearchItem(
        section: section,
        searchKeys: const [TranslationKey.cleanData],
        searchId: TranslationKey.cleanData.name,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // 设置二级页面已经提供标题和滚动容器，直接复用清理数据内容。
    return CleanDataPage(embedded: true);
  }
}
