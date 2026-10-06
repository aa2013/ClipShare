// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_connection_notify_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DeviceConnectionNotifyNotifier)
final deviceConnectionNotifyProvider =
    DeviceConnectionNotifyNotifierProvider._();

final class DeviceConnectionNotifyNotifierProvider
    extends $NotifierProvider<DeviceConnectionNotifyNotifier, void> {
  DeviceConnectionNotifyNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deviceConnectionNotifyProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deviceConnectionNotifyNotifierHash();

  @$internal
  @override
  DeviceConnectionNotifyNotifier create() => DeviceConnectionNotifyNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$deviceConnectionNotifyNotifierHash() =>
    r'53ae14d0b15b47ef2066255e352f369bdbfcd57d';

abstract class _$DeviceConnectionNotifyNotifier extends $Notifier<void> {
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
