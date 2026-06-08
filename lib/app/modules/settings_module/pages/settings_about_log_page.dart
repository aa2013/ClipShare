import 'settings_section_view_base.dart';

class SettingsAboutLogPage extends SettingsSectionView {
  SettingsAboutLogPage({super.key, super.embedded}) : super(section: SettingsSection.aboutLog);

  @override
  List<Widget> buildCards(BuildContext context) {
    return [
      SettingCardGroup(
        showHeader: showGroupHeader,
        groupName: TranslationKey.about.tr,
        icon: const Icon(Icons.info_outline),
        cardList: buildSettingEntries(context),
      ),
    ];
  }

  @override
  List<SettingEntry> buildSettingEntries(BuildContext context) {
    return [
      SettingCard(
        searchKeys: const [TranslationKey.about],
        title: Row(
          children: [
            Text(
              "${TranslationKey.about.tr} ${Constants.appName}",
              maxLines: 1,
            ),
          ],
        ),
        value: null,
        action: (v) => IconButton(
          onPressed: () {
            controller.gotoAboutPage();
          },
          icon: arrowForwardIcon,
        ),
        onTap: () {
          controller.gotoAboutPage();
        },
      ),
      SettingCard(
        searchKeys: const [TranslationKey.faq],
        searchAliases: const ['FAQ'],
        title: Row(
          children: [
            Text(TranslationKey.faq.tr, maxLines: 1),
          ],
        ),
        value: null,
        action: (v) => IconButton(
          onPressed: () {
            if (PlatformExt.isDesktop) {
              Constants.faqUrl.openUrl();
            } else {
              Constants.faqUrl.askOpenUrl();
            }
          },
          icon: arrowForwardIcon,
        ),
        onTap: () {
          if (PlatformExt.isDesktop) {
            Constants.faqUrl.openUrl();
          } else {
            Constants.faqUrl.askOpenUrl();
          }
        },
      ),
    ];
  }
}
