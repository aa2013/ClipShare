// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_sync_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 设备元数据同步处理器。

@ProviderFor(DeviceSyncNotifier)
final deviceSyncProvider = DeviceSyncNotifierProvider._();

/// 设备元数据同步处理器。
final class DeviceSyncNotifierProvider
    extends $NotifierProvider<DeviceSyncNotifier, void> {
  /// 设备元数据同步处理器。
  DeviceSyncNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deviceSyncProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deviceSyncNotifierHash();

  @$internal
  @override
  DeviceSyncNotifier create() => DeviceSyncNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$deviceSyncNotifierHash() =>
    r'e590bb90a8457fcec0ef82e53d160409474a1cd4';

/// 设备元数据同步处理器。

abstract class _$DeviceSyncNotifier extends $Notifier<void> {
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
