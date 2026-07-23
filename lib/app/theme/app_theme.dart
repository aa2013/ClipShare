import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

const lightBackgroundColor = Color.fromARGB(255, 240, 243, 249);
const lightNavigationSurfaceColor = Color(0xFFEAF0F7);
const lightSelectedNavigationColor = Color(0xFF1769AA);
const lightUnselectedNavigationColor = Color(0xFF64727D);
final _lightColorScheme = ColorScheme.fromSeed(
  seedColor: Colors.lightBlueAccent,
  surface: lightBackgroundColor,
  surfaceBright: Colors.white,
);
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
final _lightNoneBorderInputDecoration = _baseNoneBorderInputDecoration.copyWith(
  fillColor: const Color(0xFFE5E8EF),
);
final lightThemeData = ThemeData.light().copyWith(
  colorScheme: _lightColorScheme,
  appBarTheme: AppBarTheme(
    backgroundColor: _lightColorScheme.inversePrimary,
    foregroundColor: const Color(0xFF1B252C),
    elevation: 0,
    scrolledUnderElevation: 0,
    shadowColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    iconTheme: const IconThemeData(color: Color(0xFF1B252C)),
    actionsIconTheme: const IconThemeData(color: Color(0xFF1B252C)),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: lightNavigationSurfaceColor,
    elevation: 8,
    selectedItemColor: lightSelectedNavigationColor,
    unselectedItemColor: lightUnselectedNavigationColor,
    selectedIconTheme: IconThemeData(color: lightSelectedNavigationColor),
    unselectedIconTheme: IconThemeData(color: lightUnselectedNavigationColor),
    type: BottomNavigationBarType.fixed,
  ),
  cardTheme: const CardThemeData(color: Colors.white),
  scaffoldBackgroundColor: lightBackgroundColor,
  iconTheme: const IconThemeData(color: Color(0xFF1B252C)),
  textTheme: Platform.isWindows ? ThemeData.light().textTheme.apply(fontFamily: 'Microsoft YaHei') : null,
  chipTheme: ChipThemeData(
    backgroundColor: const Color(0xffdde1e3),
    selectedColor: Colors.blue[100],
    side: BorderSide.none,
  ),
  segmentedButtonTheme: SegmentedButtonThemeData(
    style: ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith<Color?>(
        (states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.blue.shade100; // 选中背景色
          }
          return Colors.transparent; // 未选中
        },
      ),
    ),
  ),
  dialogBackgroundColor: const Color(0xffdde1e3),
  canvasColor: Colors.white,
);

const darkBackgroundColor = Color(0xFF101417);
const darkBackgroundColor2 = Color(0xFF1A242A);
const darkNavigationSurfaceColor = Color(0xFF182128);
const darkNoneBorderInputColor = Color(0xFF182128);
const darkSelectedNavigationColor = Color(0xFF8FC7F3);
const darkUnselectedNavigationColor = Color(0xFF92A2AC);
final _darkColorScheme = ColorScheme.fromSeed(
  seedColor: Colors.lightBlueAccent,
  brightness: Brightness.dark,
  surface: darkBackgroundColor,
  surfaceBright: darkBackgroundColor2,
);
final _darkNoneBorderInputDecoration = _baseNoneBorderInputDecoration.copyWith(
  fillColor: darkNoneBorderInputColor,
);
final darkThemeData = ThemeData.dark().copyWith(
  colorScheme: _darkColorScheme,
  appBarTheme: const AppBarTheme(
    backgroundColor: darkNavigationSurfaceColor,
    foregroundColor: Color(0xFFE5EEF4),
    elevation: 0,
    scrolledUnderElevation: 0,
    shadowColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    iconTheme: IconThemeData(color: Color(0xFFE5EEF4)),
    actionsIconTheme: IconThemeData(color: Color(0xFFE5EEF4)),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: darkNavigationSurfaceColor,
    elevation: 8,
    selectedItemColor: darkSelectedNavigationColor,
    unselectedItemColor: darkUnselectedNavigationColor,
    selectedIconTheme: IconThemeData(color: darkSelectedNavigationColor),
    unselectedIconTheme: IconThemeData(color: darkUnselectedNavigationColor),
    type: BottomNavigationBarType.fixed,
  ),
  cardTheme: const CardThemeData(color: darkBackgroundColor2),
  scaffoldBackgroundColor: darkBackgroundColor,
  canvasColor: darkBackgroundColor2,
  iconTheme: const IconThemeData(color: Color(0xFFE5EEF4)),
  textTheme: Platform.isWindows ? ThemeData.dark().textTheme.apply(fontFamily: 'Microsoft YaHei') : null,
  chipTheme: ChipThemeData(
    backgroundColor: darkBackgroundColor2,
    selectedColor: Colors.blue[800],
    // 深色 chip 背景接近卡片色，统一补边框避免历史标签和设备 chip 融入背景。
    side: BorderSide(color: _darkColorScheme.outlineVariant.withAlpha(50)),
  ),
  dialogBackgroundColor: darkBackgroundColor2,
);


InputDecoration get noneBorderInputDecoration{
  if(Get.isDarkMode){
    return _darkNoneBorderInputDecoration;
  }
  return _lightNoneBorderInputDecoration;
}
