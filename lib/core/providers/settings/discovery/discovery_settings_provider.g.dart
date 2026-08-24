// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'discovery_settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(discoverySettings)
final discoverySettingsProvider = DiscoverySettingsProvider._();

final class DiscoverySettingsProvider
    extends
        $FunctionalProvider<
          AsyncValue<DiscoverySettings>,
          DiscoverySettings,
          FutureOr<DiscoverySettings>
        >
    with
        $FutureModifier<DiscoverySettings>,
        $FutureProvider<DiscoverySettings> {
  DiscoverySettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'discoverySettingsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$discoverySettingsHash();

  @$internal
  @override
  $FutureProviderElement<DiscoverySettings> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<DiscoverySettings> create(Ref ref) {
    return discoverySettings(ref);
  }
}

String _$discoverySettingsHash() => r'6cd4e0ca4987d984794afdec699f517166bc3cfc';
