// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'discovery_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 设备发现状态。
/// 负责组播、子网、已配对设备和中转设备发现，不拥有连接会话。

@ProviderFor(DiscoveryNotifier)
final discoveryProvider = DiscoveryNotifierProvider._();

/// 设备发现状态。
/// 负责组播、子网、已配对设备和中转设备发现，不拥有连接会话。
final class DiscoveryNotifierProvider
    extends $NotifierProvider<DiscoveryNotifier, bool> {
  /// 设备发现状态。
  /// 负责组播、子网、已配对设备和中转设备发现，不拥有连接会话。
  DiscoveryNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'discoveryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$discoveryNotifierHash();

  @$internal
  @override
  DiscoveryNotifier create() => DiscoveryNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$discoveryNotifierHash() => r'7c9dbee4f1c81f3b5aa37c1fb7a0e18abda56997';

/// 设备发现状态。
/// 负责组播、子网、已配对设备和中转设备发现，不拥有连接会话。

abstract class _$DiscoveryNotifier extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
