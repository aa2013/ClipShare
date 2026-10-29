// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hotkey_settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(hotkeySettings)
final hotkeySettingsProvider = HotkeySettingsProvider._();

final class HotkeySettingsProvider
    extends
        $FunctionalProvider<
          AsyncValue<HotkeySettings>,
          HotkeySettings,
          FutureOr<HotkeySettings>
        >
    with $FutureModifier<HotkeySettings>, $FutureProvider<HotkeySettings> {
  HotkeySettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hotkeySettingsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hotkeySettingsHash();

  @$internal
  @override
  $FutureProviderElement<HotkeySettings> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<HotkeySettings> create(Ref ref) {
    return hotkeySettings(ref);
  }
}

String _$hotkeySettingsHash() => r'6a4ccfd4b0f12321af7d951a541c620715408632';
