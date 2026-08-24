part of 'app_theme.dart';

const _darkBackgroundColor = Color(0xFF101417);
const _darkBackgroundColorBright = Color(0xFF1A242A);
const _darkNavigationSurfaceColor = Color(0xFF182128);
const _darkNoneBorderInputColor = Color(0xFF182128);
const _darkSelectedNavigationColor = Color(0xFF8FC7F3);
const _darkUnselectedNavigationColor = Color(0xFF92A2AC);
final _darkColorScheme = ColorScheme.fromSeed(
  seedColor: Colors.lightBlueAccent,
  brightness: Brightness.dark,
  surface: _darkBackgroundColor,
  surfaceBright: _darkBackgroundColorBright,
);
final darkNoneBorderInputDecoration = _baseNoneBorderInputDecoration.copyWith(
  fillColor: _darkNoneBorderInputColor,
);
final darkThemeData = ThemeData.dark().copyWith(
  colorScheme: _darkColorScheme,
  appBarTheme: const AppBarTheme(
    backgroundColor: _darkNavigationSurfaceColor,
    foregroundColor: Color(0xFFE5EEF4),
    elevation: 0,
    scrolledUnderElevation: 0,
    shadowColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    iconTheme: IconThemeData(color: Color(0xFFE5EEF4)),
    actionsIconTheme: IconThemeData(color: Color(0xFFE5EEF4)),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: _darkNavigationSurfaceColor,
    elevation: 8,
    selectedItemColor: _darkSelectedNavigationColor,
    unselectedItemColor: _darkUnselectedNavigationColor,
    selectedIconTheme: IconThemeData(color: _darkSelectedNavigationColor),
    unselectedIconTheme: IconThemeData(color: _darkUnselectedNavigationColor),
    type: BottomNavigationBarType.fixed,
  ),
  cardTheme: const CardThemeData(color: _darkBackgroundColorBright),
  scaffoldBackgroundColor: _darkBackgroundColor,
  canvasColor: _darkBackgroundColorBright,
  iconTheme: const IconThemeData(color: Color(0xFFE5EEF4)),
  textTheme: isWindows ? ThemeData.dark().textTheme.apply(fontFamily: 'Microsoft YaHei') : null,
  chipTheme: ChipThemeData(
    backgroundColor: _darkBackgroundColorBright,
    selectedColor: Colors.blue[800],
    // 深色 chip 背景接近卡片色，统一补边框避免历史标签和设备 chip 融入背景。
    side: BorderSide(color: _darkColorScheme.outlineVariant.withAlpha(50)),
  ), dialogTheme: const DialogThemeData(backgroundColor: _darkBackgroundColorBright),
);

// InputDecoration get noneBorderInputDecoration {
//   if (Get.isDarkMode) {
//     return _darkNoneBorderInputDecoration;
//   }
//   return _lightNoneBorderInputDecoration;
// }
