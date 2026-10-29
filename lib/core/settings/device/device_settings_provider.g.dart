// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(deviceSettings)
final deviceSettingsProvider = DeviceSettingsProvider._();

final class DeviceSettingsProvider
    extends
        $FunctionalProvider<
          AsyncValue<DeviceSettings>,
          DeviceSettings,
          FutureOr<DeviceSettings>
        >
    with $FutureModifier<DeviceSettings>, $FutureProvider<DeviceSettings> {
  DeviceSettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deviceSettingsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deviceSettingsHash();

  @$internal
  @override
  $FutureProviderElement<DeviceSettings> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<DeviceSettings> create(Ref ref) {
    return deviceSettings(ref);
  }
}

String _$deviceSettingsHash() => r'd8f7ac5070fbda6e0718da501795c189705dfe98';
