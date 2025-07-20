import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/**
 * GetX Template Generator - fb.com/htngu.99
 * */
const lightBackgroundColor = Color.fromARGB(255, 238, 238, 238);
const darkBackgroundColor = Colors.black;
final lightThemeData = ThemeData.light().copyWith(
  colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.lightBlueAccent, surfaceBright: Colors.white),
  cardTheme: const CardThemeData(color: Colors.white),
  scaffoldBackgroundColor: lightBackgroundColor,
  textTheme: Platform.isWindows
      ? ThemeData.light().textTheme.apply(fontFamily: 'Microsoft YaHei')
      : null,
  chipTheme: ChipThemeData(
    backgroundColor: const Color(0xffdde1e3),
    selectedColor: Colors.blue[100],
  ),
  dialogBackgroundColor: const Color(0xffdde1e3),
  canvasColor: Colors.white,
);
const darkBackgroundColor2 = Color(0xff2e3b42);
final darkThemeData = ThemeData.dark().copyWith(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.lightBlueAccent,
    brightness: Brightness.dark,
  ),
  // cardTheme: const CardTheme(color: Colors.blueGrey),
  scaffoldBackgroundColor: darkBackgroundColor,
  textTheme: Platform.isWindows
      ? ThemeData.dark().textTheme.apply(fontFamily: 'Microsoft YaHei')
      : null,
  chipTheme: ChipThemeData(
    backgroundColor: darkBackgroundColor2,
    selectedColor: Colors.blue[800],
  ),
  dialogBackgroundColor: darkBackgroundColor2,
);
