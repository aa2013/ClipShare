// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quick_settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 聚合快捷设置分区所需状态，字段来源保持独立以便单项设置刷新时只失效对应缓存。

@ProviderFor(quickSettings)
final quickSettingsProvider = QuickSettingsProvider._();

/// 聚合快捷设置分区所需状态，字段来源保持独立以便单项设置刷新时只失效对应缓存。

final class QuickSettingsProvider
    extends
        $FunctionalProvider<
          AsyncValue<QuickSettings>,
          QuickSettings,
          FutureOr<QuickSettings>
        >
    with $FutureModifier<QuickSettings>, $FutureProvider<QuickSettings> {
  /// 聚合快捷设置分区所需状态，字段来源保持独立以便单项设置刷新时只失效对应缓存。
  QuickSettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'quickSettingsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$quickSettingsHash();

  @$internal
  @override
  $FutureProviderElement<QuickSettings> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<QuickSettings> create(Ref ref) {
    return quickSettings(ref);
  }
}

String _$quickSettingsHash() => r'fd950b505a46b5d6cb265f4fc9bfea58d1007277';

/// 读取当前开机启动状态；该检测包含平台查询，只有开机启动配置变化时才应主动刷新。

@ProviderFor(appLaunchAtStartup)
final appLaunchAtStartupProvider = AppLaunchAtStartupProvider._();

/// 读取当前开机启动状态；该检测包含平台查询，只有开机启动配置变化时才应主动刷新。

final class AppLaunchAtStartupProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// 读取当前开机启动状态；该检测包含平台查询，只有开机启动配置变化时才应主动刷新。
  AppLaunchAtStartupProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appLaunchAtStartupProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appLaunchAtStartupHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return appLaunchAtStartup(ref);
  }
}

String _$appLaunchAtStartupHash() =>
    r'35243ec3a56ba912c475d0301b14fa6e65f04bc2';

/// 读取启动最小化偏好，供快捷设置 UI 和桌面启动窗口展示逻辑复用。

@ProviderFor(startMini)
final startMiniProvider = StartMiniProvider._();

/// 读取启动最小化偏好，供快捷设置 UI 和桌面启动窗口展示逻辑复用。

final class StartMiniProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// 读取启动最小化偏好，供快捷设置 UI 和桌面启动窗口展示逻辑复用。
  StartMiniProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'startMiniProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$startMiniHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return startMini(ref);
  }
}

String _$startMiniHash() => r'd133ebc9eacd234132ee0dbf341276ad4f800df9';

/// 读取应用语言偏好，返回已解析的语言枚举以便 UI 直接展示生效选项。

@ProviderFor(language)
final languageProvider = LanguageProvider._();

/// 读取应用语言偏好，返回已解析的语言枚举以便 UI 直接展示生效选项。

final class LanguageProvider
    extends
        $FunctionalProvider<
          AsyncValue<AppLanguage>,
          AppLanguage,
          FutureOr<AppLanguage>
        >
    with $FutureModifier<AppLanguage>, $FutureProvider<AppLanguage> {
  /// 读取应用语言偏好，返回已解析的语言枚举以便 UI 直接展示生效选项。
  LanguageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'languageProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$languageHash();

  @$internal
  @override
  $FutureProviderElement<AppLanguage> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<AppLanguage> create(Ref ref) {
    return language(ref);
  }
}

String _$languageHash() => r'4399aff210d02f9ae77c266783e3ef4879095a43';

/// 读取应用主题模式偏好，供启动主题、系统主题同步和设置页选择器共用。

@ProviderFor(appTheme)
final appThemeProvider = AppThemeProvider._();

/// 读取应用主题模式偏好，供启动主题、系统主题同步和设置页选择器共用。

final class AppThemeProvider
    extends
        $FunctionalProvider<
          AsyncValue<ThemeMode>,
          ThemeMode,
          FutureOr<ThemeMode>
        >
    with $FutureModifier<ThemeMode>, $FutureProvider<ThemeMode> {
  /// 读取应用主题模式偏好，供启动主题、系统主题同步和设置页选择器共用。
  AppThemeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appThemeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appThemeHash();

  @$internal
  @override
  $FutureProviderElement<ThemeMode> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<ThemeMode> create(Ref ref) {
    return appTheme(ref);
  }
}

String _$appThemeHash() => r'eaa1f9bd2f6a90b6a587c3d3a9312058a1143653';
