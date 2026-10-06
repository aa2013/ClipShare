// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transport_heartbeat_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 统一管理传输层心跳生命周期，具体心跳内容由各传输服务自行实现。

@ProviderFor(TransportHeartbeatNotifier)
final transportHeartbeatProvider = TransportHeartbeatNotifierProvider._();

/// 统一管理传输层心跳生命周期，具体心跳内容由各传输服务自行实现。
final class TransportHeartbeatNotifierProvider
    extends $NotifierProvider<TransportHeartbeatNotifier, void> {
  /// 统一管理传输层心跳生命周期，具体心跳内容由各传输服务自行实现。
  TransportHeartbeatNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transportHeartbeatProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transportHeartbeatNotifierHash();

  @$internal
  @override
  TransportHeartbeatNotifier create() => TransportHeartbeatNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$transportHeartbeatNotifierHash() =>
    r'eb2f745e2bcb76e73c7c703ba038d88147bab104';

/// 统一管理传输层心跳生命周期，具体心跳内容由各传输服务自行实现。

abstract class _$TransportHeartbeatNotifier extends $Notifier<void> {
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
