import 'package:clipshare/app/data/enums/app_language.dart';
import 'package:get/get.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/modules/settings_module/settings_section.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/widgets/settings/card/setting_card.dart';
import 'package:clipshare/app/widgets/settings/card/setting_card_group.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        SettingCard<AppLanguage>(
          searchKeys: const [TranslationKey.selectLanguage],
          searchAliases: [item.label, item.value.storageValue],
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

  /// 处理用户点击语言项后的切换逻辑。
  void _selectLanguage(AppLanguage language) {
    HapticFeedback.selectionClick();
    appConfig.setAppLanguage(language);
  }
}

class _LanguageBadge extends StatelessWidget {
  final AppLanguage language;

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

  /// 根据语言类型构建徽标内容，跟随系统时展示通用图标。
  Widget _buildContent(Color color) {
    if (language.isAuto) {
      return Icon(
        Icons.language_rounded,
        size: 18,
        color: color,
      );
    }
    return Text(
      language.badgeText!,
      style: TextStyle(
        color: color,
        fontSize: language.badgeFontSize,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
