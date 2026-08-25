import 'package:clipshare/core/constants/app_constants.dart';
import 'package:clipshare/core/theme/app/app_theme.dart';
import 'package:flutter/material.dart';

extension ContextExtension on BuildContext {
  MediaQueryData get media => MediaQuery.of(this);

  bool get isLandscape => media.orientation == Orientation.landscape;

  bool get isCompactScreen => media.size.width <= smallScreenWidth;

  ThemeData get currentTheme => Theme.of(this);

  bool get isDarkMode => media.platformBrightness == Brightness.dark;

  InputDecoration get noneBorderInputDecoration => isDarkMode
      ? darkNoneBorderInputDecoration
      : lightNoneBorderInputDecoration;
}
