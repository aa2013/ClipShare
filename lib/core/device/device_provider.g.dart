// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DeviceNotifier)
final deviceProvider = DeviceNotifierProvider._();

final class DeviceNotifierProvider
    extends $AsyncNotifierProvider<DeviceNotifier, DeviceState> {
  DeviceNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deviceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deviceNotifierHash();

  @$internal
  @override
  DeviceNotifier create() => DeviceNotifier();
}

String _$deviceNotifierHash() => r'647933e894ab04c727a095932ae784c0ca86599e';

abstract class _$DeviceNotifier extends $AsyncNotifier<DeviceState> {
  FutureOr<DeviceState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<DeviceState>, DeviceState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<DeviceState>, DeviceState>,
              AsyncValue<DeviceState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
