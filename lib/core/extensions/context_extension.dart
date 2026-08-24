import 'package:clipshare/core/constants/app_constants.dart';
import 'package:flutter/material.dart';

extension ContextExtension on BuildContext {
  MediaQueryData get media => MediaQuery.of(this);

  bool get isLandscape => media.orientation == Orientation.landscape;

  bool get isCompactScreen => media.size.width <= smallScreenWidth;

  ThemeData get currentTheme => Theme.of(this);
}
