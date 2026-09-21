// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'preference_settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(preferenceSettings)
final preferenceSettingsProvider = PreferenceSettingsProvider._();

final class PreferenceSettingsProvider
    extends
        $FunctionalProvider<
          AsyncValue<PreferenceSettings>,
          PreferenceSettings,
          FutureOr<PreferenceSettings>
        >
    with
        $FutureModifier<PreferenceSettings>,
        $FutureProvider<PreferenceSettings> {
  PreferenceSettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'preferenceSettingsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$preferenceSettingsHash();

  @$internal
  @override
  $FutureProviderElement<PreferenceSettings> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PreferenceSettings> create(Ref ref) {
    return preferenceSettings(ref);
  }
}

String _$preferenceSettingsHash() =>
    r'1e382797a1239b7df3b7ad382d68a5706a0853a7';
