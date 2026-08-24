// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(syncSettings)
final syncSettingsProvider = SyncSettingsProvider._();

final class SyncSettingsProvider
    extends
        $FunctionalProvider<
          AsyncValue<SyncSettings>,
          SyncSettings,
          FutureOr<SyncSettings>
        >
    with $FutureModifier<SyncSettings>, $FutureProvider<SyncSettings> {
  SyncSettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncSettingsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncSettingsHash();

  @$internal
  @override
  $FutureProviderElement<SyncSettings> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<SyncSettings> create(Ref ref) {
    return syncSettings(ref);
  }
}

String _$syncSettingsHash() => r'b3c9f0292063b1af12e09499144fb512bb5286de';
