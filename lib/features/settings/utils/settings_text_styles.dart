import 'package:flutter/material.dart';

/// 设置页辅助说明文字的统一样式入口。
///
/// 设置页的一级副标题、二级页副标题和设置项说明都使用同一套
/// 颜色层级，避免在各个 widget 中散落重复的透明度与行高配置。
abstract final class SettingsTextStyles {
  static const double _subtitleAlpha = 0.68;
  static const double _subtitleIconAlpha = 0.56;
  static const double _overviewSubtitleHeight = 1.18;
  static const double _settingDescriptionHeight = 1.25;

  static Color subtitleColor(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface.withValues(
          alpha: _subtitleAlpha,
        );
  }

  static Color subtitleIconColor(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface.withValues(
          alpha: _subtitleIconAlpha,
        );
  }

  static TextStyle? overviewSubtitle(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall?.copyWith(
          color: subtitleColor(context),
          height: _overviewSubtitleHeight,
        );
  }

  static TextStyle? sectionSubtitle(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall?.copyWith(
          color: subtitleColor(context),
        );
  }

  static TextStyle settingDescription(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium!.copyWith(
          color: subtitleColor(context),
          height: _settingDescriptionHeight,
        );
  }
}
