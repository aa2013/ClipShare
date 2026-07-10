import 'package:clipshare/app/modules/settings_module/settings_section_view_factory.dart';
import 'package:clipshare/app/modules/settings_module/settings_section.dart';
import 'package:clipshare/app/modules/settings_module/settings_text_styles.dart';
import 'package:clipshare/app/widgets/settings/card/setting_card.dart';
import 'package:flutter/material.dart';

class SettingsSectionContentPage extends StatelessWidget {
  final SettingsSection? section;
  final bool embedded;
  final String? highlightedSearchId;

  const SettingsSectionContentPage({
    super.key,
    this.section,
    this.embedded = false,
    this.highlightedSearchId,
  });

  @override
  Widget build(BuildContext context) {
    final targetSection = section ?? SettingsSection.preference;
    final content = SettingSearchHighlightScope(
      searchId: highlightedSearchId,
      child: buildSettingsSectionContent(targetSection, embedded: embedded),
    );
    if (targetSection == SettingsSection.statistics) {
      return content;
    }
    if (embedded) {
      return _buildEmbeddedSection(context, targetSection, content);
    }
    return Scaffold(
      appBar: AppBar(
        title: _SettingsSectionAppBarTitle(section: targetSection),
      ),
      body: content,
    );
  }

  Widget _buildEmbeddedSection(
    BuildContext context,
    SettingsSection targetSection,
    Widget content,
  ) {
    final theme = Theme.of(context);
    final iconBg = _sectionIconBackground(context);
    return Material(
      color: theme.colorScheme.surface,
      child: SafeArea(
        child: Container(
          color: theme.colorScheme.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 12),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: iconBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(targetSection.icon, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            targetSection.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          if (targetSection.subtitle.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              targetSection.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: SettingsTextStyles.sectionSubtitle(context),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: content),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsSectionAppBarTitle extends StatelessWidget {
  final SettingsSection section;

  const _SettingsSectionAppBarTitle({
    required this.section,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          section.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

Color _sectionIconBackground(BuildContext context) {
  final theme = Theme.of(context);
  if (theme.brightness == Brightness.light) {
    return Color.alphaBlend(
      Colors.blueGrey.withValues(alpha: 0.12),
      theme.colorScheme.surface,
    );
  }
  return Color.alphaBlend(
    Colors.blueGrey.withValues(alpha: 0.20),
    theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface,
  );
}
