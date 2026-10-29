import 'package:flutter/material.dart';

/// 子窗口运行时配置状态（由启动参数初始化，运行期可被主窗口推送更新）。
class MultiWindowConfigState {
  /// 为 true 表示当前引擎运行在子窗口模式。
  final bool enabled;

  final Locale? locale;
  final ThemeMode themeMode;

  /// 失焦是否自动关闭弹窗。
  final bool autoClosePopupOnBlur;

  /// 单击条目直接粘贴。
  final bool clickToPaste;

  const MultiWindowConfigState({
    this.enabled = false,
    this.locale,
    this.themeMode = ThemeMode.system,
    this.autoClosePopupOnBlur = false,
    this.clickToPaste = false,
  });

  MultiWindowConfigState copyWith({
    bool? enabled,
    Locale? locale,
    ThemeMode? themeMode,
    bool? autoClosePopupOnBlur,
    bool? clickToPaste,
  }) {
    return MultiWindowConfigState(
      enabled: enabled ?? this.enabled,
      locale: locale ?? this.locale,
      themeMode: themeMode ?? this.themeMode,
      autoClosePopupOnBlur: autoClosePopupOnBlur ?? this.autoClosePopupOnBlur,
      clickToPaste: clickToPaste ?? this.clickToPaste,
    );
  }
}
