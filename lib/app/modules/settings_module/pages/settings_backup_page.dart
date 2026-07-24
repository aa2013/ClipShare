import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'settings_section_view_base.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/modules/settings_module/settings_section.dart';
import 'package:clipshare/app/widgets/settings/card/setting_card.dart';
import 'package:clipshare/app/widgets/settings/card/setting_card_group.dart';
import 'package:flutter/material.dart';

class SettingsBackupPage extends SettingsSectionView {
  SettingsBackupPage({super.key, super.embedded}) : super(section: SettingsSection.backup);

  @override
  List<Widget> buildCards(BuildContext context) {
    return [
      SettingCardGroup(
        showHeader: showGroupHeader,
        groupName: TranslationKey.backupRestore.tr,
        icon: const Icon(MdiIcons.backupRestore),
        cardList: buildSettingEntries(context),
      ),
    ];
  }

  @override
  List<SettingEntry> buildSettingEntries(BuildContext context) {
    return [
      SettingCard(
        searchKeys: const [
          TranslationKey.backup,
          TranslationKey.backupSettingDesc,
        ],
        title: Text(TranslationKey.backup.tr),
        description: Text(TranslationKey.backupSettingDesc.tr),
        value: null,
        action: (v) {
          return TextButton(
            onPressed: () => controller.startBackup(context),
            child: Text(TranslationKey.startUp.tr),
          );
        },
      ),
      SettingCard(
        searchKeys: const [
          TranslationKey.restore,
          TranslationKey.restoreSettingDesc,
        ],
        title: Text(TranslationKey.restore.tr),
        description: Text(TranslationKey.restoreSettingDesc.tr),
        value: null,
        action: (v) {
          return TextButton(
            onPressed: () => controller.restore(context),
            child: Text(TranslationKey.selection.tr),
          );
        },
      ),
    ];
  }
}
