// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'socket_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SocketNotifier)
final socketProvider = SocketNotifierProvider._();

final class SocketNotifierProvider
    extends $NotifierProvider<SocketNotifier, SocketState> {
  SocketNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'socketProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$socketNotifierHash();

  @$internal
  @override
  SocketNotifier create() => SocketNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SocketState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SocketState>(value),
    );
  }
}

String _$socketNotifierHash() => r'f145de39952ab64df8b60dec6cb0e550baaf7516';

abstract class _$SocketNotifier extends $Notifier<SocketState> {
  SocketState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<SocketState, SocketState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SocketState, SocketState>,
              SocketState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
