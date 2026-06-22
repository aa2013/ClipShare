import 'package:clipshare/app/modules/settings_module/pages/settings_section_view_base.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/widgets/check_update_button.dart';
import 'package:simple_icons/simple_icons.dart';

const aboutPageInstructionsSearchId = 'about_page_instructions';
const aboutPageFaqSearchId = 'about_page_faq';

class SettingsAboutPage extends SettingsSectionView {
  SettingsAboutPage({super.key, super.embedded}) : super(section: SettingsSection.aboutLog);

  final dbService = Get.find<DbService>();

  @override
  List<Widget> buildCards(BuildContext context) {
    return [
      // Keep external resources separate from diagnostics/version details.
      SettingCardGroup(
        showHeader: false,
        cardList: buildSettingsAboutSupportEntries(
          onOpenInstructions: () {
            if (PlatformExt.isDesktop) {
              Constants.usageWeb.openUrl();
            } else {
              Constants.usageWeb.askOpenUrl();
            }
          },
          onOpenFaq: () {
            if (PlatformExt.isDesktop) {
              Constants.faqUrl.openUrl();
            } else {
              Constants.faqUrl.askOpenUrl();
            }
          },
          onOpenLicenses: controller.gotoLicensesPage,
          onOpenGithub: () {
            if (PlatformExt.isDesktop) {
              Constants.githubRepo.openUrl();
            } else {
              Constants.githubRepo.askOpenUrl();
            }
          },
          onOpenQqGroup: () {
            Constants.qqGroup.openUrl();
          },
          onOpenWebsite: () {
            if (PlatformExt.isDesktop) {
              Constants.clipshareSite.openUrl();
            } else {
              Constants.clipshareSite.askOpenUrl();
            }
          },
        ),
      ),
      const SizedBox(height: 12),
      SettingCardGroup(
        showHeader: false,
        cardList: buildSettingsAboutDetailEntries(
          appVersionText: appConfig.version.toString(),
          dbVersionText: dbService.version.toString(),
          onOpenUpdateLog: controller.gotoUpdateLogsPage,
          onOpenDbEditor: () {
            Get.toNamed(Routes.DB_EDITOR);
          },
          versionAction: const CheckUpdateButton(),
        ),
      ),
    ];
  }

  @override
  List<SettingEntry> buildSettingEntries(BuildContext context) {
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
        appVersionText: appConfig.version.toString(),
        dbVersionText: dbService.version.toString(),
        onOpenUpdateLog: () {},
        onOpenDbEditor: () {},
        versionAction: const SizedBox.shrink(),
      ),
    ];
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
      searchAliases: const [Constants.appName],
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
