// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'forward_settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(forwardSettings)
final forwardSettingsProvider = ForwardSettingsProvider._();

final class ForwardSettingsProvider
    extends
        $FunctionalProvider<
          AsyncValue<ForwardSettings>,
          ForwardSettings,
          FutureOr<ForwardSettings>
        >
    with $FutureModifier<ForwardSettings>, $FutureProvider<ForwardSettings> {
  ForwardSettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'forwardSettingsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$forwardSettingsHash();

  @$internal
  @override
  $FutureProviderElement<ForwardSettings> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ForwardSettings> create(Ref ref) {
    return forwardSettings(ref);
  }
}

String _$forwardSettingsHash() => r'86aa2fa8f37296e2aff06e7a3cbb77389de32a34';
