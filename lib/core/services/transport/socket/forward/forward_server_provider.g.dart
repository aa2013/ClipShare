// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'forward_server_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 中转控制连接和中转设备发现

@ProviderFor(ForwardServerNotifier)
final forwardServerProvider = ForwardServerNotifierProvider._();

/// 中转控制连接和中转设备发现
final class ForwardServerNotifierProvider
    extends $NotifierProvider<ForwardServerNotifier, bool> {
  /// 中转控制连接和中转设备发现
  ForwardServerNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'forwardServerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$forwardServerNotifierHash();

  @$internal
  @override
  ForwardServerNotifier create() => ForwardServerNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$forwardServerNotifierHash() =>
    r'd5994957e6c21ab0657417cb29b57438e43c01f0';

/// 中转控制连接和中转设备发现

abstract class _$ForwardServerNotifier extends $Notifier<bool> {
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
