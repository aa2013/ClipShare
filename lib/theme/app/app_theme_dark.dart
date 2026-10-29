part of 'app_theme.dart';

const _darkBackgroundColor = Color(0xFF101417);
const _darkBackgroundColorBright = Color(0xFF1A242A);
const _darkNavigationSurfaceColor = Color(0xFF182128);
const _darkNoneBorderInputColor = Color(0xFF182128);
const _darkSelectedNavigationColor = Color(0xFF8FC7F3);
const _darkUnselectedNavigationColor = Color(0xFF92A2AC);

// 前景色，对应深色背景上的文字、图标、强调文字
const _darkForegroundColor = Color(0xFFE5EEF4);

// 验证码输入框的格子填充色，需比弹窗背景色亮一档，否则格子边界与背景贴合
const _darkPinFillColor = Color(0xFF23303A);
final _darkColorScheme = ColorScheme.fromSeed(
  seedColor: Colors.lightBlueAccent,
  brightness: Brightness.dark,
  surface: _darkBackgroundColor,
  surfaceBright: _darkBackgroundColorBright,
);
final darkNoneBorderInputDecoration = _baseNoneBorderInputDecoration.copyWith(
  fillColor: _darkNoneBorderInputColor,
);

/// 验证码输入框（Pinput）主题，格子填充色比弹窗背景色亮一档。
///
/// [Pinput] 的六个状态主题不做字段级合并，只要给定 [defaultPinTheme]，
/// 未单独指定的聚焦、已输入、错误等状态都会回落到它，因此这里一套即可覆盖全部状态。
const darkPinTheme = PinTheme(
  width: pinInputBoxSize,
  height: pinInputBoxSize,
  textStyle: TextStyle(
    fontSize: pinInputFontSize,
    fontWeight: FontWeight.w600,
    color: _darkForegroundColor,
  ),
  decoration: BoxDecoration(
    color: _darkPinFillColor,
    borderRadius: BorderRadius.all(Radius.circular(pinInputBoxCornerRadius)),
  ),
);

final darkThemeData = ThemeData.dark().copyWith(
  colorScheme: _darkColorScheme,
  appBarTheme: const AppBarTheme(
    backgroundColor: _darkNavigationSurfaceColor,
    foregroundColor: _darkForegroundColor,
    elevation: 0,
    scrolledUnderElevation: 0,
    shadowColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    iconTheme: IconThemeData(color: _darkForegroundColor),
    actionsIconTheme: IconThemeData(color: _darkForegroundColor),
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
  iconTheme: const IconThemeData(color: _darkForegroundColor),
  textTheme: isWindows ? ThemeData.dark().textTheme.apply(fontFamily: 'Microsoft YaHei') : null,
  chipTheme: ChipThemeData(
    backgroundColor: _darkBackgroundColorBright,
    selectedColor: Colors.blue[800],
    // 深色 chip 背景接近卡片色，统一补边框避免历史标签和设备 chip 融入背景。
    side: BorderSide(color: _darkColorScheme.outlineVariant.withAlpha(50)),
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: _darkBackgroundColorBright,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(dialogCornerRadius),
    ),
  ),
);

// InputDecoration get noneBorderInputDecoration {
//   if (Get.isDarkMode) {
//     return _darkNoneBorderInputDecoration;
//   }
//   return _lightNoneBorderInputDecoration;
// }
