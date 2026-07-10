import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/modules/settings_module/settings_section.dart';
import 'package:clipshare/app/modules/settings_module/settings_text_styles.dart';
import 'package:clipshare/app/modules/settings_module/widgets/settings_section_icon.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SettingsSectionTile extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = theme.cardTheme.color ?? theme.colorScheme.surface;
    final bgColor = selected ? selectedSettingsTileColor(context, cardColor) : cardColor;
    final subtitle = _sectionSubtitle();
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
  String _sectionSubtitle() {
    if (section == SettingsSection.log) {
      return '';
    }
    if (section == SettingsSection.language) {
      final appConfig = Get.find<ConfigService>();
      for (final lg in Constants.languageSelections) {
        if (lg.value == appConfig.language) {
          return lg.label;
        }
      }
      return TranslationKey.unknown.tr;
    }
    return section.subtitle;
  }
}
