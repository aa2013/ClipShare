part of 'app_theme.dart';

const _lightBackgroundColor = Color.fromARGB(255, 240, 243, 249);
const _lightNavigationSurfaceColor = Color(0xFFEAF0F7);
const _lightSelectedNavigationColor = Color(0xFF1769AA);
const _lightUnselectedNavigationColor = Color(0xFF64727D);

// 前景色，对应浅色背景上的文字、图标、强调文字
const _lightForegroundColor = Color(0xFF1B252C);

// 输入框填充色
const _lightInputFillColor = Color(0xFFE5E8EF);
final _lightColorScheme = ColorScheme.fromSeed(
  seedColor: Colors.lightBlueAccent,
  surface: _lightBackgroundColor,
  surfaceBright: Colors.white,
);
final lightNoneBorderInputDecoration = _baseNoneBorderInputDecoration.copyWith(
  fillColor: _lightInputFillColor,
);

/// 验证码输入框（Pinput）主题，格子填充色与浅色输入框一致。
///
/// [Pinput] 的六个状态主题不做字段级合并，只要给定 [defaultPinTheme]，
/// 未单独指定的聚焦、已输入、错误等状态都会回落到它，因此这里一套即可覆盖全部状态。
const lightPinTheme = PinTheme(
  width: pinInputBoxSize,
  height: pinInputBoxSize,
  textStyle: TextStyle(
    fontSize: pinInputFontSize,
    fontWeight: FontWeight.w600,
    color: _lightForegroundColor,
  ),
  decoration: BoxDecoration(
    color: _lightInputFillColor,
    borderRadius: BorderRadius.all(Radius.circular(pinInputBoxCornerRadius)),
  ),
);

final lightThemeData = ThemeData.light().copyWith(
  colorScheme: _lightColorScheme,
  appBarTheme: AppBarTheme(
    backgroundColor: _lightColorScheme.inversePrimary,
    foregroundColor: _lightForegroundColor,
    elevation: 0,
    scrolledUnderElevation: 0,
    shadowColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    iconTheme: const IconThemeData(color: _lightForegroundColor),
    actionsIconTheme: const IconThemeData(color: _lightForegroundColor),
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
  iconTheme: const IconThemeData(color: _lightForegroundColor),
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
  canvasColor: Colors.white,
  dialogTheme: DialogThemeData(
    backgroundColor: const Color(0xffdde1e3),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(dialogCornerRadius),
    ),
  ),
);
