import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'package:clipshare/core/theme/app/app_theme.dart';
import 'package:clipshare/shared/extensions/context_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 基于 [BuildContext] 的主题相关扩展。
extension ThemeContextExtension on BuildContext {
  /// 无边框输入框装饰，按当前明暗模式选择。
  InputDecoration get noneBorderInputDecoration => isDarkMode
      ? darkNoneBorderInputDecoration
      : lightNoneBorderInputDecoration;

  /// 切换明暗主题并同步系统 UI 样式。
  void updateTheme(
    bool isDark, {
    VoidCallback? onAnimationFinish,
  }) {
    ThemeSwitcher.of(this).changeTheme(
      theme: isDark ? darkThemeData : lightThemeData,
      isReversed: false,
      onAnimationFinish: onAnimationFinish,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isDark) {
        setSystemUIOverlayDarkStyle();
      } else {
        setSystemUIOverlayLightStyle();
      }
    });
    //todo
    // final windowChannelService = Get.find<MultiWindowChannelService>();
    // //updateConfig 是异步 IPC，窗口引用陈旧时 reject，需 catchError 兜住（Bug1 同款）
    // windowChannelService.updateConfig(MultiWindowConfig.themeMode, themeMode.name).catchError((_) {});
  }

  ///将底部导航栏设置为深色
  void setSystemUIOverlayDarkStyle() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle.dark.copyWith(
          systemNavigationBarColor: currentTheme.colorScheme.surfaceBright,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      );
    });
  }

  ///将底部导航栏设置为浅色
  void setSystemUIOverlayLightStyle() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle.light.copyWith(
          systemNavigationBarColor: currentTheme.colorScheme.surface,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      );
    });
  }

  ///根据当前主题设置底部导航栏样式
  void setSystemUIOverlayAutoStyle() {
    if (isDarkMode) {
      setSystemUIOverlayDarkStyle();
    } else {
      setSystemUIOverlayLightStyle();
    }
  }
}
