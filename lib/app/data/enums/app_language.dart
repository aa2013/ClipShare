import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:flutter/material.dart';

/// 应用支持的语言配置。
enum AppLanguage {
  auto(_autoStorageValue),
  zhCN(_zhCnStorageValue),
  enUS(_enUsStorageValue);

  static const String _autoStorageValue = 'auto';
  static const String _zhCnStorageValue = 'zh_CN';
  static const String _enUsStorageValue = 'en_US';
  static const String _zhCnLabel = '简体中文';
  static const String _enUsLabel = 'English';
  static const String _zhCnBadgeText = '中';
  static const String _enUsBadgeText = 'EN';
  static const double _zhCnBadgeFontSize = 16;
  static const double _enUsBadgeFontSize = 13;
  static const Locale zhCnLocale = Locale('zh', 'CN');
  static const Locale enUsLocale = Locale('en', 'US');
  static const Locale defaultLocale = enUsLocale;
  static const List<AppLanguage> supportedValues = [AppLanguage.zhCN, AppLanguage.enUS];
  static const List<AppLanguage> selectableValues = [AppLanguage.auto, ...supportedValues];

  const AppLanguage(this.storageValue);

  /// 持久化到本地配置中的语言编码。
  final String storageValue;

  /// 标记当前语言是否跟随系统。
  bool get isAuto => this == AppLanguage.auto;

  /// 返回当前语言对应的显示名称。
  String get label {
    switch (this) {
      case AppLanguage.auto:
        return TranslationKey.auto.tr;
      case AppLanguage.zhCN:
        return _zhCnLabel;
      case AppLanguage.enUS:
        return _enUsLabel;
    }
  }

  /// 返回语言徽标文本；跟随系统时返回空以显示图标。
  String? get badgeText {
    switch (this) {
      case AppLanguage.auto:
        return null;
      case AppLanguage.zhCN:
        return _zhCnBadgeText;
      case AppLanguage.enUS:
        return _enUsBadgeText;
    }
  }

  /// 返回语言徽标的字号，便于统一复用展示逻辑。
  double get badgeFontSize {
    switch (this) {
      case AppLanguage.auto:
        return _enUsBadgeFontSize;
      case AppLanguage.zhCN:
        return _zhCnBadgeFontSize;
      case AppLanguage.enUS:
        return _enUsBadgeFontSize;
    }
  }

  /// 返回当前语言固定绑定的 Locale。
  Locale get locale {
    switch (this) {
      case AppLanguage.zhCN:
        return zhCnLocale;
      case AppLanguage.auto:
      case AppLanguage.enUS:
        return enUsLocale;
    }
  }

  /// 将持久化字符串安全解析为枚举，未知值统一回退到自动语言。
  static AppLanguage fromStorageValue(String? value) {
    for (final language in selectableValues) {
      if (language.storageValue == value) {
        return language;
      }
    }
    return AppLanguage.auto;
  }

  /// 基于设备语言解析当前应生效的 Locale。
  Locale resolveLocale([Locale? deviceLocale]) {
    if (isAuto) {
      return deviceLocale ?? defaultLocale;
    }
    return locale;
  }
}
