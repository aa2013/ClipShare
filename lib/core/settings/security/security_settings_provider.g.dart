// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'security_settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(securitySettings)
final securitySettingsProvider = SecuritySettingsProvider._();

final class SecuritySettingsProvider
    extends
        $FunctionalProvider<
          AsyncValue<SecuritySettings>,
          SecuritySettings,
          FutureOr<SecuritySettings>
        >
    with $FutureModifier<SecuritySettings>, $FutureProvider<SecuritySettings> {
  SecuritySettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'securitySettingsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$securitySettingsHash();

  @$internal
  @override
  $FutureProviderElement<SecuritySettings> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<SecuritySettings> create(Ref ref) {
    return securitySettings(ref);
  }
}

String _$securitySettingsHash() => r'd6ca1c014b14aafa325e8976d2142bc4ecf6f97a';
