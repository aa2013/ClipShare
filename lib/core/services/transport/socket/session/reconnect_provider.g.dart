// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reconnect_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 独立维护每台设备的重连任务和重连窗口。

@ProviderFor(ReconnectNotifier)
final reconnectProvider = ReconnectNotifierProvider._();

/// 独立维护每台设备的重连任务和重连窗口。
final class ReconnectNotifierProvider
    extends $NotifierProvider<ReconnectNotifier, void> {
  /// 独立维护每台设备的重连任务和重连窗口。
  ReconnectNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reconnectProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reconnectNotifierHash();

  @$internal
  @override
  ReconnectNotifier create() => ReconnectNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$reconnectNotifierHash() => r'834a05ae40da379282ed96008496b18bfa980c9f';

/// 独立维护每台设备的重连任务和重连窗口。

abstract class _$ReconnectNotifier extends $Notifier<void> {
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
