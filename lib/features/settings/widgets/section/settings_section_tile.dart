import 'package:clipshare/core/extensions/context_extension.dart';
import 'package:clipshare/core/providers/settings/quick/quick_settings_provider.dart';
import 'package:clipshare/features/settings/enums/settings_section.dart';
import 'package:clipshare/features/settings/utils/settings_text_styles.dart';
import 'package:clipshare/features/settings/widgets/section/settings_section_icon.dart';
import 'package:clipshare/l10n/app_language.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsSectionTile extends ConsumerWidget {
  final SettingsSection section;
  final VoidCallback onTap;
  final bool selected;

  const SettingsSectionTile({
    super.key,
    required this.section,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quickSettings = ref.watch(quickSettingsProvider).requireValue;
    final theme = context.currentTheme;
    final cardColor = theme.cardTheme.color ?? theme.colorScheme.surface;
    final bgColor = selected ? selectedSettingsTileColor(context, cardColor) : cardColor;
    final subtitle = _sectionSubtitle(quickSettings.language);
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              SettingsSectionIcon(section: section),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      section.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: SettingsTextStyles.sectionSubtitle(context),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.chevron_right_rounded, color: Colors.blueGrey),
            ],
          ),
        ),
      ),
    );
  }

  /// 生成设置分区副标题，语言分区需要展示当前生效的语言名称。
  String _sectionSubtitle(AppLanguage currentLanguage) {
    if (section == SettingsSection.log) {
      return '';
    }
    if (section == SettingsSection.language) {
      for (final lg in languageSelections) {
        if (lg.value == currentLanguage) {
          return lg.label;
        }
      }
      return TranslationKey.unknown.tr;
    }
    return section.subtitle;
  }
}
