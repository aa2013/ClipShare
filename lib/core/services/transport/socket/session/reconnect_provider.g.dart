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
    extends $NotifierProvider<ReconnectNotifier, Set<String>> {
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
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }
}

String _$reconnectNotifierHash() => r'a80e494d6b30279e051dc59416004548fd58bf10';

/// 独立维护每台设备的重连任务和重连窗口。

abstract class _$ReconnectNotifier extends $Notifier<Set<String>> {
  Set<String> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Set<String>, Set<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Set<String>, Set<String>>,
              Set<String>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
