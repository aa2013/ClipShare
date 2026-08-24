import 'dart:convert';
import 'dart:ui';

import 'package:clipshare/shared/enums/multi_window/multi_window_tag.dart';
import 'package:flutter/material.dart';

/// 可跨 Flutter 引擎传递的子窗口启动参数。
class DesktopMultiWindowArgs {
  final MultiWindowTag tag;
  final String title;
  final String languageCode;
  final String? countryCode;
  final ThemeMode themeMode;

  /// 子窗口失焦时是否自动隐藏，需与主窗口偏好一致。
  final bool autoClosePopupOnBlur;

  /// 主窗口传入的本机设备标识，供子窗口独立计算设备展示名。
  final String selfDeviceGuid;
  final Map<String, dynamic> otherArgs;

  DesktopMultiWindowArgs._private({
    required this.tag,
    required this.title,
    required this.languageCode,
    this.countryCode,
    required this.themeMode,
    required this.autoClosePopupOnBlur,
    required this.selfDeviceGuid,
    this.otherArgs = const {},
  });

  /// 根据主窗口运行时状态创建子窗口启动参数。
  ///
  /// [platformBrightness] / [locale] 用于在不依赖 GetX 时解析 system 主题与当前语言。
  factory DesktopMultiWindowArgs.init({
    required String title,
    required MultiWindowTag tag,
    required ThemeMode? themeMode,
    required bool autoClosePopupOnBlur,
    required String selfDeviceGuid,
    required Locale locale,
    Brightness? platformBrightness,
    Map<String, dynamic> otherArgs = const {},
  }) {
    final brightness = platformBrightness ?? PlatformDispatcher.instance.platformBrightness;
    final resolvedThemeMode = themeMode == null || themeMode == ThemeMode.system
        ? (brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light)
        : themeMode;
    return DesktopMultiWindowArgs._private(
      tag: tag,
      title: title,
      languageCode: locale.languageCode,
      countryCode: locale.countryCode,
      themeMode: resolvedThemeMode,
      autoClosePopupOnBlur: autoClosePopupOnBlur,
      selfDeviceGuid: selfDeviceGuid,
      otherArgs: otherArgs,
    );
  }

  @override
  String toString() => jsonEncode(toJson());

  /// 序列化为可跨引擎传递的 Map。
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'tag': tag.name,
      'title': title,
      'languageCode': languageCode,
      'themeMode': themeMode.name,
      'autoClosePopupOnBlur': autoClosePopupOnBlur,
      'selfDeviceGuid': selfDeviceGuid,
      'otherArgs': otherArgs,
    };
    if (countryCode != null) {
      map['countryCode'] = countryCode!;
    }
    return map;
  }

  /// 将动态 Map 安全转为 `Map<String, dynamic>`。
  static Map<String, dynamic> _asStringKeyMap(dynamic value) {
    if (value == null) {
      return const {};
    }
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    throw FormatException('otherArgs must be a Map, got ${value.runtimeType}');
  }

  /// 解析 themeMode 字段；非法值回退到系统亮度。
  static ThemeMode _parseThemeMode(dynamic rawThemeMode, Brightness brightness) {
    if (rawThemeMode == null || rawThemeMode == 'system') {
      return brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light;
    }
    if (rawThemeMode is! String) {
      return brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light;
    }
    try {
      final mode = ThemeMode.values.byName(rawThemeMode);
      if (mode == ThemeMode.system) {
        return brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light;
      }
      return mode;
    } catch (_) {
      return brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light;
    }
  }

  /// 解析子窗口启动参数；缺少本机标识时回退为空字符串以保持可启动。
  factory DesktopMultiWindowArgs.fromJson(
    Map<String, dynamic> json, {
    Brightness? platformBrightness,
  }) {
    final brightness = platformBrightness ?? PlatformDispatcher.instance.platformBrightness;
    final title = json['title'];
    final languageCode = json['languageCode'];
    final tag = json['tag'];
    if (title is! String || title.isEmpty) {
      throw const FormatException('DesktopMultiWindowArgs missing title');
    }
    if (languageCode is! String || languageCode.isEmpty) {
      throw const FormatException('DesktopMultiWindowArgs missing languageCode');
    }
    if (tag is! String || tag.isEmpty) {
      throw const FormatException('DesktopMultiWindowArgs missing tag');
    }
    return DesktopMultiWindowArgs._private(
      tag: MultiWindowTag.getValue(tag),
      title: title,
      languageCode: languageCode,
      countryCode: json['countryCode'] as String?,
      themeMode: _parseThemeMode(json['themeMode'], brightness),
      autoClosePopupOnBlur: json['autoClosePopupOnBlur'] as bool? ?? false,
      selfDeviceGuid: json['selfDeviceGuid'] as String? ?? '',
      otherArgs: _asStringKeyMap(json['otherArgs']),
    );
  }
}
