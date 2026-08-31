import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'package:clipshare/core/constants/app_constants.dart';
import 'package:clipshare/core/theme/app/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

extension ContextExtension on BuildContext {
  MediaQueryData get media => MediaQuery.of(this);

  bool get isLandscape => media.orientation == Orientation.landscape;

  bool get isCompactScreen => media.size.width <= smallScreenWidth;

  ThemeData get currentTheme => Theme.of(this);

  Brightness get platformBrightness => media.platformBrightness;

  bool get isPlatformDarkMode => platformBrightness == Brightness.dark;

  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  InputDecoration get noneBorderInputDecoration => isDarkMode
      ? darkNoneBorderInputDecoration
      : lightNoneBorderInputDecoration;

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
