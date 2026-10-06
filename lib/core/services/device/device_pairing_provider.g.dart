// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_pairing_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DevicePairingCodeNotifier)
final devicePairingCodeProvider = DevicePairingCodeNotifierProvider._();

final class DevicePairingCodeNotifierProvider
    extends $NotifierProvider<DevicePairingCodeNotifier, void> {
  DevicePairingCodeNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'devicePairingCodeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$devicePairingCodeNotifierHash();

  @$internal
  @override
  DevicePairingCodeNotifier create() => DevicePairingCodeNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$devicePairingCodeNotifierHash() =>
    r'e63f6aaa6241c6e96d07344451e4e0ef4437fc3f';

abstract class _$DevicePairingCodeNotifier extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
