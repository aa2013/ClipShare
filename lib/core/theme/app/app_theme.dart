import 'package:clipshare/core/constants/platform_constants.dart';
import 'package:flutter/material.dart';

part 'app_theme_light.dart';

part 'app_theme_dark.dart';

final _baseNoneBorderInputDecoration = InputDecoration(
  isDense: true,
  filled: true,
  hoverColor: Colors.transparent,
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8), // 8px 圆角
    borderSide: BorderSide.none, // 无边框线
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide.none,
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide.none,
  ),
);
