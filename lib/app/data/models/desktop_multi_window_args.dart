import 'dart:convert';

import 'package:clipshare/app/data/enums/multi_window_tag.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DesktopMultiWindowArgs {
  final MultiWindowTag tag;
  final String title;
  final String languageCode;
  String? countryCode;
  final ThemeMode themeMode;
  /// 控制子窗口在失去焦点时是否自动走隐藏流程，保证首次创建时与主窗口偏好一致。
  final bool autoClosePopupOnBlur;
  /// 由主窗口传入子窗口的本机设备标识，用于子窗口独立计算设备展示名。
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

  /// 根据主窗口运行时状态创建可跨 Flutter 引擎传递的子窗口启动参数。
  factory DesktopMultiWindowArgs.init({
    required String title,
    required MultiWindowTag tag,
    required ThemeMode? themeMode,
    required bool autoClosePopupOnBlur,
    required String selfDeviceGuid,
    Map<String, dynamic> otherArgs = const {},
  }) {
    final locale = Get.locale!;
    themeMode = themeMode == ThemeMode.system || themeMode == null
        ? Get.isPlatformDarkMode
            ? ThemeMode.dark
            : ThemeMode.light
        : themeMode;
    return DesktopMultiWindowArgs._private(
      tag: tag,
      title: title,
      languageCode: locale.languageCode,
      countryCode: locale.countryCode,
      themeMode: themeMode,
      autoClosePopupOnBlur: autoClosePopupOnBlur,
      selfDeviceGuid: selfDeviceGuid,
      otherArgs: otherArgs,
    );
  }

  @override
  String toString() {
    return jsonEncode(this);
  }

  /// 启动上下文
  Map<String, dynamic> toJson() {
    var map = {
      "tag": tag.name,
      "title": title,
      "languageCode": languageCode,
      "themeMode": themeMode.name,
      "autoClosePopupOnBlur": autoClosePopupOnBlur,
      "selfDeviceGuid": selfDeviceGuid,
      "otherArgs": otherArgs,
    };
    if (countryCode != null) {
      map["countryCode"] = countryCode!;
    }
    return map;
  }

  /// 解析子窗口启动参数，缺少本机标识的旧参数回退为空字符串以保持可启动。
  factory DesktopMultiWindowArgs.fromJson(Map<String, dynamic> json) {
    ThemeMode themeMode = !json.containsKey('themeMode') || json['themeMode'] == "system"
        ? Get.isPlatformDarkMode
            ? ThemeMode.dark
            : ThemeMode.light
        : json['themeMode'] == "light"
            ? ThemeMode.light
            : ThemeMode.dark;
    return DesktopMultiWindowArgs._private(
      tag: MultiWindowTag.getValue(json['tag']!),
      title: json['title']!,
      languageCode: json['languageCode']!,
      countryCode: json['countryCode'],
      themeMode: themeMode,
      autoClosePopupOnBlur: json['autoClosePopupOnBlur'] ?? false,
      selfDeviceGuid: json['selfDeviceGuid'] ?? "",
      otherArgs: json["otherArgs"] ?? {},
    );
  }
}
