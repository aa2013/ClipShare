import 'dart:async';
import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'package:clipshare/app/data/enums/channelMethods/multi_window_method.dart';
import 'package:clipshare/app/data/enums/multi_window_config.dart';
import 'package:clipshare/app/data/models/desktop_multi_window_args.dart';
import 'package:clipshare/app/services/multi_window_dispatch_service.dart';
import 'package:clipshare/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MultiWindowConfigService extends GetxService implements MultiWindowMessageListener {
  Locale? _locale;

  Locale? get locale => _locale;

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  bool _autoClosePopupOnBlur = false;

  bool get autoClosePopupOnBlur => _autoClosePopupOnBlur;

  bool _clickToPaste = false;

  /// 单击条目直接粘贴开关（主窗口通过 otherArgs 传入初始值，运行期由 updateConfig 推送同步）
  bool get clickToPaste => _clickToPaste;

  MultiWindowConfigService(DesktopMultiWindowArgs args) {
    _locale = Locale(args.languageCode, args.countryCode);
    _themeMode = args.themeMode;
    _autoClosePopupOnBlur = args.autoClosePopupOnBlur;
    _clickToPaste = args.otherArgs[MultiWindowConfig.clickToPaste.name] as bool? ?? false;
  }

  @override
  void onReady() {
    super.onReady();
    multiWindowMsgDispatchService.addListener(this);
  }

  @override
  void onClose() {
    super.onClose();
    multiWindowMsgDispatchService.removeListener(this);
  }

  @override
  FutureOr<void> onMultiWindowMessage(MultiWindowMethod method, Map<String, dynamic> args, int fromWindowId) async {
    if (method != MultiWindowMethod.updateConfig) {
      return;
    }
    final allConfigs = MultiWindowConfig.values.map((c) => c.name).toList(growable: false);
    var configKeys = args.keys.where(allConfigs.contains).map(MultiWindowConfig.values.byName);
    for (var key in configKeys) {
      try {
        final value = args[key.name];
        switch (key) {
          case MultiWindowConfig.language:
            _onLanguageChanged(value);
            break;
          case MultiWindowConfig.themeMode:
            _onThemeModeChanged(value);
            break;
          case MultiWindowConfig.autoClosePopupOnBlur:
            _onAutoClosePopupOnBlurChanged(value);
            break;
          case MultiWindowConfig.clickToPaste:
            _onClickToPasteChanged(value);
            break;
        }
      } catch (err, stack) {
        debugPrint(err.toString());
        debugPrintStack(stackTrace: stack);
      }
    }
  }

  void _onLanguageChanged(Map value){
    var locale = Locale(value['languageCode'], value['countryCode']);
    Get.updateLocale(locale);
    _locale = locale;
  }

  void _onThemeModeChanged(String value){
    _themeMode = ThemeMode.values.byName(value);
    ThemeSwitcher.of(Get.context!).changeTheme(
      theme: _themeMode == ThemeMode.dark ? darkThemeData : lightThemeData,
      isReversed: false,
    );
  }

  /// 同步主窗口的弹窗失焦关闭偏好，避免子窗口在运行期间保留旧值。
  void _onAutoClosePopupOnBlurChanged(bool value) {
    _autoClosePopupOnBlur = value;
  }

  /// 同步主窗口的单击粘贴偏好（弹窗常驻不销毁，设置切换后不重启也生效）。
  void _onClickToPasteChanged(bool value) {
    _clickToPaste = value;
  }

}
