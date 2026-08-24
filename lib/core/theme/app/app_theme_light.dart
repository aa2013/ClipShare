part of 'app_theme.dart';

const _lightBackgroundColor = Color.fromARGB(255, 240, 243, 249);
const _lightNavigationSurfaceColor = Color(0xFFEAF0F7);
const _lightSelectedNavigationColor = Color(0xFF1769AA);
const _lightUnselectedNavigationColor = Color(0xFF64727D);
final _lightColorScheme = ColorScheme.fromSeed(
  seedColor: Colors.lightBlueAccent,
  surface: _lightBackgroundColor,
  surfaceBright: Colors.white,
);
final lightNoneBorderInputDecoration = _baseNoneBorderInputDecoration.copyWith(
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
    backgroundColor: _lightNavigationSurfaceColor,
    elevation: 8,
    selectedItemColor: _lightSelectedNavigationColor,
    unselectedItemColor: _lightUnselectedNavigationColor,
    selectedIconTheme: IconThemeData(color: _lightSelectedNavigationColor),
    unselectedIconTheme: IconThemeData(color: _lightUnselectedNavigationColor),
    type: BottomNavigationBarType.fixed,
  ),
  cardTheme: const CardThemeData(color: Colors.white),
  scaffoldBackgroundColor: _lightBackgroundColor,
  iconTheme: const IconThemeData(color: Color(0xFF1B252C)),
  textTheme: isWindows ? ThemeData.light().textTheme.apply(fontFamily: 'Microsoft YaHei') : null,
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
  canvasColor: Colors.white, dialogTheme: const DialogThemeData(backgroundColor: Color(0xffdde1e3)),
);
