// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'network_change_coordinator_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(NetworkChangeCoordinator)
final networkChangeCoordinatorProvider = NetworkChangeCoordinatorProvider._();

final class NetworkChangeCoordinatorProvider
    extends $NotifierProvider<NetworkChangeCoordinator, void> {
  NetworkChangeCoordinatorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'networkChangeCoordinatorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$networkChangeCoordinatorHash();

  @$internal
  @override
  NetworkChangeCoordinator create() => NetworkChangeCoordinator();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$networkChangeCoordinatorHash() =>
    r'8aca09c0c2dabe00a6896519b78b53d15fc9eace';

abstract class _$NetworkChangeCoordinator extends $Notifier<void> {
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
