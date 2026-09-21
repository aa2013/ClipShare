import 'package:clipshare/shared/constants/ui_constants.dart';
import 'package:flutter/material.dart';

extension ContextExtension on BuildContext {
  /// 当前 MediaQuery 数据。
  MediaQueryData get media => MediaQuery.of(this);

  /// 是否横屏。
  bool get isLandscape => media.orientation == Orientation.landscape;

  /// 是否为紧凑（小）屏幕。
  bool get isCompactScreen => media.size.width <= smallScreenWidth;

  /// 当前主题数据。
  ThemeData get currentTheme => Theme.of(this);

  /// 系统亮度。
  Brightness get platformBrightness => media.platformBrightness;

  /// 系统是否处于深色模式。
  bool get isPlatformDarkMode => platformBrightness == Brightness.dark;

  /// 当前主题是否为深色。
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  ///当前主题默认文本样式
  TextStyle get defaultTextStyle => DefaultTextStyle.of(this).style;
}
