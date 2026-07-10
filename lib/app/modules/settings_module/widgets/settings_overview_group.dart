import 'package:clipshare/app/modules/settings_module/settings_text_styles.dart';
import 'package:clipshare/app/modules/settings_module/widgets/settings_section_icon.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SettingsOverviewGroup extends StatelessWidget {
  final List<SettingsOverviewTile> children;

  const SettingsOverviewGroup({
    super.key,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final visibleChildren = children.where((child) => child.visible).toList();
    if (visibleChildren.isEmpty) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Material(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        child: Column(
          children: [
            for (var i = 0; i < visibleChildren.length; i++) ...[
              visibleChildren[i],
              if (i != visibleChildren.length - 1)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class SettingsOverviewTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final IconData? subtitleIcon;
  final String? subtitleTooltip;
  final Color tone;
  final Widget trailing;
  final VoidCallback? onTap;
  final bool visible;
  final bool selected;

  const SettingsOverviewTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.subtitleIcon,
    this.subtitleTooltip,
    required this.tone,
    required this.trailing,
    this.onTap,
    this.visible = true,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    final cardColor = theme.cardTheme.color ?? theme.colorScheme.surface;
    final selectedColor = selectedSettingsTileColor(context, cardColor);
    return ColoredBox(
      color: selected ? selectedColor : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: Get.isDarkMode ? 0.20 : 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: tone, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (subtitle.isNotEmpty || subtitleIcon != null) ...[
                      const SizedBox(height: 3),
                      _SettingsOverviewSubtitle(
                        text: subtitle,
                        icon: subtitleIcon,
                        tooltip: subtitleTooltip,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsOverviewSubtitle extends StatelessWidget {
  final String text;
  final IconData? icon;
  final String? tooltip;

  const _SettingsOverviewSubtitle({
    required this.text,
    this.icon,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    // 概览卡片副标题保持单行，版本等辅助信息应放到右侧区域避免状态文本换行。
    final style = SettingsTextStyles.overviewSubtitle(context);
    if (icon == null) {
      final child = Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
      return _wrapTooltip(child);
    }
    return _wrapTooltip(
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: SettingsTextStyles.subtitleIconColor(context),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
        ],
      ),
    );
  }

  Widget _wrapTooltip(Widget child) {
    if (tooltip == null || tooltip!.isEmpty) {
      return child;
    }
    return Tooltip(
      message: tooltip!,
      child: child,
    );
  }
}
