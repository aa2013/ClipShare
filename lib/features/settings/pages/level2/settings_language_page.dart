import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/extensions/context_extension.dart';
import 'package:clipshare/core/providers/settings/quick/quick_settings_provider.dart';
import 'package:clipshare/features/settings/enums/settings_section.dart';
import 'package:clipshare/features/settings/pages/settings_section_view_base.dart';
import 'package:clipshare/features/settings/widgets/card/setting_card.dart';
import 'package:clipshare/features/settings/widgets/card/setting_card_group.dart';
import 'package:clipshare/features/settings/widgets/card/setting_entry.dart';
import 'package:clipshare/l10n/app_language.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/enums/config_key.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsLanguagePage extends SettingsSectionView {
  const SettingsLanguagePage({super.key, super.embedded}) : super(section: SettingsSection.language);

  @override
  List<Widget> buildCards(BuildContext context, WidgetRef ref) {
    return [
      SettingCardGroup(
        showHeader: showGroupHeader,
        groupName: TranslationKey.selectLanguage.tr,
        icon: const Icon(Icons.language_rounded),
        cardList: buildSettingEntries(context, ref),
      ),
    ];
  }

  @override
  List<SettingEntry> buildSettingEntries(BuildContext context, WidgetRef ref) {
    final selectedLanguage = ref
        .watch(languageProvider)
        .maybeWhen(
          data: (value) => value,
          orElse: () => null,
        );
    return [
      for (final item in languageSelections)
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
          onTap: () => _selectLanguage(item.value, ref),
          action: (value) {
            if (selectedLanguage == null || value != selectedLanguage) {
              return const SizedBox(width: 24);
            }
            return Icon(
              Icons.check_rounded,
              color: Theme.of(context).colorScheme.primary,
            );
          },
        ),
    ];
  }

  /// 处理用户点击语言项后的切换逻辑。
  Future<void> _selectLanguage(AppLanguage language, WidgetRef ref) async {
    await HapticFeedback.selectionClick();
    final db = ref.read(appDbProvider).requireValue;
    await db.configDao.addOrUpdate(ConfigKey.appLanguage, language.storageValue);
    ref.invalidate(languageProvider);

    // final locale = language.resolveLocale(Get.deviceLocale);
    // Get.updateLocale(locale);
    //todo
    //updateConfig 是异步 IPC，窗口引用陈旧时 reject，需 catchError 兜住（Bug1 同款）
    // windowChannelService.updateConfig(MultiWindowConfig.language, {
    //   'languageCode': locale.languageCode,
    //   'countryCode': locale.countryCode,
    // }).catchError((_) {});
    // final homeController = Get.find<HomeController>();
    // homeController.initNavBarItems();
    // final settingController = Get.find<SettingsController>();
    // settingController.checkAndroidEnvPermission();
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
    final bgColor = theme.colorScheme.onSurface.withValues(alpha: context.isDarkMode ? 0.14 : 0.08);
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
