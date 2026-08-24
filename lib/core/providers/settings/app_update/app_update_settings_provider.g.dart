// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_update_settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(appUpdateSettings)
final appUpdateSettingsProvider = AppUpdateSettingsProvider._();

final class AppUpdateSettingsProvider
    extends
        $FunctionalProvider<
          AsyncValue<AppUpdateSettings>,
          AppUpdateSettings,
          FutureOr<AppUpdateSettings>
        >
    with
        $FutureModifier<AppUpdateSettings>,
        $FutureProvider<AppUpdateSettings> {
  AppUpdateSettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appUpdateSettingsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appUpdateSettingsHash();

  @$internal
  @override
  $FutureProviderElement<AppUpdateSettings> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<AppUpdateSettings> create(Ref ref) {
    return appUpdateSettings(ref);
  }
}

String _$appUpdateSettingsHash() => r'68221f754081bc5512e25c61d24a76d2c3aaff5d';
