import 'package:clipshare/core/constants/app_constants.dart';
import 'package:clipshare/core/constants/platform_constants.dart';
import 'package:clipshare/core/constants/url_constants.dart';
import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/services/device/local_device_info_provider.dart';
import 'package:clipshare/features/home/providers/drawer_provider.dart';
import 'package:clipshare/features/licenses/pages/licenses_page.dart';
import 'package:clipshare/features/settings/enums/settings_section.dart';
import 'package:clipshare/features/settings/pages/settings_section_view_base.dart';
import 'package:clipshare/features/settings/widgets/card/setting_card.dart';
import 'package:clipshare/features/settings/widgets/card/setting_card_group.dart';
import 'package:clipshare/features/settings/widgets/card/setting_entry.dart';
import 'package:clipshare/features/settings/widgets/check_update_button.dart';
import 'package:clipshare/features/update_log/pages/update_log_page.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/routing/app_routes.dart';
import 'package:clipshare/shared/extensions/context_extension.dart';
import 'package:clipshare/shared/extensions/string_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:simple_icons/simple_icons.dart';

const aboutPageInstructionsSearchId = 'about_page_instructions';
const aboutPageFaqSearchId = 'about_page_faq';

class SettingsAboutPage extends SettingsSectionView {
  const SettingsAboutPage({super.key, super.embedded}) : super(section: SettingsSection.aboutLog);

  @override
  List<Widget> buildCards(BuildContext context, WidgetRef ref) {
    final appVersion = ref.watch(localDeviceInfoProvider).requireValue.appVersion;
    final dbVersion = ref.read(appDbProvider).requireValue.schemaVersion;
    return [
      // Keep external resources separate from diagnostics/version details.
      SettingCardGroup(
        showHeader: false,
        cardList: buildSettingsAboutSupportEntries(
          onOpenInstructions: () {
            if (isDesktop) {
              usageWeb.openUrl();
            } else {
              usageWeb.askOpenUrl(context);
            }
          },
          onOpenFaq: () {
            if (isDesktop) {
              faqUrl.openUrl();
            } else {
              faqUrl.askOpenUrl(context);
            }
          },
          onOpenLicenses: () {
            _openLicensesPage(context, ref);
          },
          onOpenGithub: () {
            if (isDesktop) {
              githubRepo.openUrl();
            } else {
              githubRepo.askOpenUrl(context);
            }
          },
          onOpenQqGroup: () {
            qqGroup.openUrl();
          },
          onOpenWebsite: () {
            if (isDesktop) {
              clipshareSite.openUrl();
            } else {
              clipshareSite.askOpenUrl(context);
            }
          },
        ),
      ),
      const SizedBox(height: 12),
      SettingCardGroup(
        showHeader: false,
        cardList: buildSettingsAboutDetailEntries(
          appVersionText: appVersion.toString(),
          dbVersionText: dbVersion.toString(),
          onOpenUpdateLog: () {
            _openUpdateLogPage(context, ref);
          },
          onOpenDbEditor: () {
            context.pushNamed(AppRoutes.dbEditor.name);
          },
          versionAction: const CheckUpdateButton(),
        ),
      ),
    ];
  }

  @override
  List<SettingEntry> buildSettingEntries(BuildContext context, WidgetRef ref) {
    final appVersion = ref.watch(localDeviceInfoProvider).requireValue.appVersion;
    final dbVersion = ref.read(appDbProvider).requireValue.schemaVersion;
    return [
      ...buildSettingsAboutSupportEntries(
        onOpenInstructions: () {},
        onOpenFaq: () {},
        onOpenLicenses: () {},
        onOpenGithub: () {},
        onOpenQqGroup: () {},
        onOpenWebsite: () {},
      ),
      ...buildSettingsAboutDetailEntries(
        appVersionText: appVersion.toString(),
        dbVersionText: dbVersion.toString(),
        onOpenUpdateLog: () {},
        onOpenDbEditor: () {},
        versionAction: const SizedBox.shrink(),
      ),
    ];
  }

  /// 打开许可证页
  void _openLicensesPage(BuildContext context, WidgetRef ref) {
    if (context.isCompactScreen) {
      context.pushNamed(AppRoutes.licenses.name);
      return;
    }
    final drawer = ref.read(drawerProvider);
    drawer.controller.push(const LicensesPage(), null);
  }

  /// 打开更新日志页
  void _openUpdateLogPage(BuildContext context, WidgetRef ref) {
    if (context.isCompactScreen) {
      context.pushNamed(AppRoutes.updateLog.name);
      return;
    }
    final drawer = ref.read(drawerProvider);
    drawer.controller.push(const UpdateLogPage(), null);
  }
}

List<SettingEntry> buildSettingsAboutSupportEntries({
  required VoidCallback onOpenInstructions,
  required VoidCallback onOpenFaq,
  required VoidCallback onOpenLicenses,
  required VoidCallback onOpenGithub,
  required VoidCallback onOpenQqGroup,
  required VoidCallback onOpenWebsite,
}) {
  return [
    SettingCard(
      padding: const EdgeInsets.all(16),
      // Use the item label as the primary search title and let the section
      // subtitle cover broader "about" matches.
      searchKeys: const [TranslationKey.aboutPageInstructionsItemName],
      searchAliases: const [appName],
      searchId: aboutPageInstructionsSearchId,
      title: _buildAboutItemTitle(
        icon: Icons.help_outline_outlined,
        text: TranslationKey.aboutPageInstructionsItemName.tr,
      ),
      value: null,
      onTap: onOpenInstructions,
    ),
    SettingCard(
      padding: const EdgeInsets.all(16),
      searchKeys: const [TranslationKey.faq],
      searchAliases: const ['FAQ'],
      searchId: aboutPageFaqSearchId,
      title: _buildAboutItemTitle(
        icon: Icons.quiz_outlined,
        text: TranslationKey.faq.tr,
      ),
      value: null,
      onTap: onOpenFaq,
    ),
    SettingCard(
      padding: const EdgeInsets.all(16),
      searchAliases: const ['Licenses', 'License'],
      title: _buildAboutItemTitle(
        icon: Icons.event_note_outlined,
        text: 'Licenses',
      ),
      value: null,
      onTap: onOpenLicenses,
    ),
    SettingCard(
      padding: const EdgeInsets.all(16),
      searchAliases: const ['GitHub', 'Github'],
      title: _buildAboutItemTitle(
        icon: SimpleIcons.github,
        text: 'GitHub',
      ),
      value: null,
      onTap: onOpenGithub,
    ),
    SettingCard(
      padding: const EdgeInsets.all(16),
      searchKeys: const [TranslationKey.aboutPageJoinQQGroupItemName],
      title: _buildAboutItemTitle(
        icon: SimpleIcons.qq,
        text: TranslationKey.aboutPageJoinQQGroupItemName.tr,
      ),
      value: null,
      onTap: onOpenQqGroup,
    ),
    SettingCard(
      padding: const EdgeInsets.all(16),
      searchKeys: const [TranslationKey.aboutPageWebsiteItemName],
      title: _buildAboutItemTitle(
        icon: MdiIcons.web,
        text: TranslationKey.aboutPageWebsiteItemName.tr,
      ),
      value: null,
      onTap: onOpenWebsite,
    ),
  ];
}

List<SettingEntry> buildSettingsAboutDetailEntries({
  required String appVersionText,
  required String dbVersionText,
  required VoidCallback onOpenUpdateLog,
  required VoidCallback onOpenDbEditor,
  required Widget versionAction,
}) {
  return [
    SettingCard(
      padding: const EdgeInsets.all(16),
      searchKeys: const [TranslationKey.aboutPageLogsItemName],
      title: _buildAboutItemTitle(
        icon: MdiIcons.update,
        text: TranslationKey.aboutPageLogsItemName.tr,
      ),
      value: null,
      onTap: onOpenUpdateLog,
    ),
    SettingCard(
      padding: const EdgeInsets.all(16),
      searchKeys: const [TranslationKey.aboutPageVersionItemName],
      title: _buildAboutDetailTitle(
        icon: Icons.info_outline,
        title: TranslationKey.aboutPageVersionItemName.tr,
        subtitle: appVersionText,
      ),
      value: null,
      action: (_) => versionAction,
    ),
    SettingCard(
      padding: const EdgeInsets.all(16),
      searchKeys: const [
        TranslationKey.aboutPageDatabaseVersionItemName,
        TranslationKey.editDb,
      ],
      title: _buildAboutDetailTitle(
        icon: MdiIcons.databaseOutline,
        title: TranslationKey.aboutPageDatabaseVersionItemName.tr,
        subtitle: dbVersionText,
      ),
      value: null,
      action: (_) {
        return Tooltip(
          message: TranslationKey.editDb.tr,
          child: IconButton(
            onPressed: onOpenDbEditor,
            icon: const Icon(
              Icons.search_outlined,
              color: Colors.blueGrey,
            ),
          ),
        );
      },
    ),
  ];
}

Widget _buildAboutItemTitle({
  required IconData icon,
  required String text,
}) {
  return Row(
    children: [
      Icon(
        icon,
        color: Colors.blueGrey,
        size: 28,
      ),
      const SizedBox(width: 16),
      Text(
        text,
        style: const TextStyle(fontSize: 16),
      ),
    ],
  );
}

Widget _buildAboutDetailTitle({
  required IconData icon,
  required String title,
  required String subtitle,
}) {
  return Row(
    children: [
      Icon(
        icon,
        color: Colors.blueGrey,
        size: 28,
      ),
      const SizedBox(width: 16),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16),
          ),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    ],
  );
}
