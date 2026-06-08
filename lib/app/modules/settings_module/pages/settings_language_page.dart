import 'settings_section_view_base.dart';

class SettingsLanguagePage extends SettingsSectionView {
  SettingsLanguagePage({super.key, super.embedded}) : super(section: SettingsSection.language);

  @override
  List<Widget> buildCards(BuildContext context) {
    return [
      SettingCardGroup(
        showHeader: showGroupHeader,
        groupName: TranslationKey.selectLanguage.tr,
        icon: const Icon(Icons.language_rounded),
        cardList: buildSettingEntries(context),
      ),
    ];
  }

  @override
  List<SettingEntry> buildSettingEntries(BuildContext context) {
    return [
      for (final item in Constants.languageSelections)
        SettingCard<String>(
          searchKeys: const [TranslationKey.selectLanguage],
          searchAliases: [item.label, item.value],
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LanguageBadge(language: item.value),
              const SizedBox(width: 12),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          value: item.value,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          onTap: () => _selectLanguage(item.value),
          action: (value) {
            return Obx(() {
              if (value != appConfig.language) {
                return const SizedBox(width: 24);
              }
              return Icon(
                Icons.check_rounded,
                color: Theme.of(context).colorScheme.primary,
              );
            });
          },
        ),
    ];
  }

  void _selectLanguage(String language) {
    HapticFeedback.selectionClick();
    appConfig.setAppLanguage(language);
  }
}

class _LanguageBadge extends StatelessWidget {
  final String language;

  const _LanguageBadge({
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = theme.colorScheme.onSurface.withValues(alpha: Get.isDarkMode ? 0.14 : 0.08);
    final textColor = theme.colorScheme.onSurface.withValues(alpha: 0.78);
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: _buildContent(textColor),
    );
  }

  Widget _buildContent(Color color) {
    if (language == 'auto') {
      return Icon(
        Icons.language_rounded,
        size: 18,
        color: color,
      );
    }
    return Text(
      language == 'zh_CN' ? '中' : 'EN',
      style: TextStyle(
        color: color,
        fontSize: language == 'zh_CN' ? 16 : 13,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
